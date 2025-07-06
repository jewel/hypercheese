require_dependency 'search'
require 'digest'

class ItemsController < ApplicationController
  respond_to :json

  def index
    search_key = params[:search_key]
    path = Rails.root.join('tmp/searches').join search_key if search_key

    if search_key == '' || path && !path.exist?
      query = params[:query] || {}
      query[:current_user] = current_user
      search = Search.new query
      ids = search.ids
      str = ids.pack 'V*'
      search_key = Digest::MD5.hexdigest str
      dir = Rails.root.join('tmp/searches')
      Dir.mkdir dir unless dir.exist?
      path = dir + search_key
      temp = "#{path}.#$$.tmp"
      File.binwrite temp, str
      File.rename temp, path
    end

    raise "Invalid key" unless search_key =~ /\A[a-f0-9]{32}\Z/

    limit = (params[:limit] || 1000).to_i
    offset = (params[:offset] || 0).to_i

    bytes_per_id = 4 # 32-bit

    total = path.size / bytes_per_id

    subset = nil

    path.open('rb') do |f|
      f.seek offset * bytes_per_id
      str = f.read limit * bytes_per_id
      str ||= ""
      subset = str.unpack 'V*'
    end

    res = Item.includes(:comments, :tags, :stars, :bullhorns, :ratings).find subset

    # `find` returns unordered, sort according to desired order
    items_by_id = {}
    res.each do |item|
      items_by_id[item.id] = item
    end

    res = subset.map do |item_id|
      items_by_id[item_id.to_i]
    end

    render json: res, each_serializer: ItemSerializer, root: "items", meta: { search_key: search_key, total: total }
  end

  def visibility
    value = params[:value] == 'true'
    ids = items_params[:items].map { |_| _.to_i }
    items = Item.where id: ids
    items.check_visibility_for current_user
    Item.transaction do
      items.each do |item|
        item.published = value
        item.save
      end
    end
    UpdateActivityJob.perform_later
  end

  def shares
    require_write!

    code = SecureRandom.urlsafe_base64 8

    Share.transaction do
      share = Share.new
      share.user = current_user
      share.code = code
      share.save

      ids = items_params[:items].map { |_| _.to_i }
      items = Item.where id: ids
      items.check_visibility_for current_user

      items.pluck(:id).each do |item_id|
        ShareItem.create share: share, item_id: item_id
      end
    end

    url = "#{request.protocol}#{request.host_with_port}/shares/#{code}"

    render json: { url: url }
  end

  def show
    id = params[:id].to_i
    @item = Item.find id
    @item.check_visibility_for current_user

    query = params[:query] || {}
    query[:current_user] = current_user
    search = Search.new query
    index = search.ids.index id

    render json: @item, meta: { index: index }
  end

  def add_tags
    require_write!

    items = nil

    current_user_id = current_user && current_user.id

    Item.transaction do
      tags = Tag.find item_tag_params[:tags]
      items = Item.includes(:tags).find item_tag_params[:items]
      items.each do |item|
        item.check_visibility_for current_user
      end

      items.each do |item|
        tags.each do |tag|
          next if item.tags.member? tag
          ItemTag.create item: item, tag: tag, added_by: current_user_id
        end
      end
    end

    # reload to refresh new associations
    items = Item.includes(:tags).find item_tag_params[:items]

    render json: items, each_serializer: ItemSerializer
  end

  def remove_tag
    require_write!

    items = nil
    Item.transaction do
      tag = Tag.find params[:tag].to_i
      items = Item.includes(:tags).find item_tag_params[:items]
      items.each do |item|
        item.check_visibility_for current_user
      end

      items.each do |item|
        next unless item.tags.member? tag
        item.tags.delete tag
      end
    end

    render json: items, each_serializer: ItemSerializer
  end

  def toggle_star
    require_write!

    @item = Item.includes(:stars).where(id: params[:item_id].to_i).first
    @item.check_visibility_for current_user
    star = @item.stars.where(user_id: current_user.id).first
    if star
      star.destroy
    else
      @item.starred_by.push current_user
    end

    @item.reload

    render json: @item, serializer: ItemSerializer
  end

  def toggle_bullhorn
    require_write!

    @item = Item.includes(:bullhorns).find params[:item_id].to_i
    @item.check_visibility_for current_user
    bullhorn = @item.bullhorns.where(user_id: current_user.id).first
    if bullhorn
      bullhorn.destroy
    else
      @item.bullhorned_by.push current_user
    end

    @item.reload

    render json: @item, serializer: ItemSerializer
  end

  def rate
    require_write!

    @item = Item.includes(:ratings).find params[:item_id].to_i
    @item.check_visibility_for current_user
    rating = @item.ratings.where(user_id: current_user.id).first
    rating.destroy if rating

    Rating.create!(item: @item, user: current_user, value: params[:value])

    @item.reload
    render json: @item, serializer: ItemSerializer
  end

  def download
    ids = params[:ids].split(/,/).map { |_| _.to_i }
    items = Item.where(id: ids).includes(:item_paths)
    download_zip items
  end

  def convert
    ids = params[:ids].split(/,/).map { |_| _.to_i }
    items = Item.where(id: ids).includes(:item_paths)
    convert_to_jpeg_and_zip items
  end

  # GET /items/:id/details
  def details
    @item = Item.includes(:comments, :stars, :faces, :locations).find params[:item_id].to_i
    @item.check_visibility_for current_user
    render json: @item, serializer: ItemDetailsSerializer, include: 'comments.user'
  end

  # Backwards compatibility for new code URLs for items
  def resized
    expires_in 10.years
    item = Item.find params[:item_id].to_i
    item.check_visibility_for current_user
    redirect_to "/data/resized/#{params[:size]}/#{item.id}-#{item.code}.#{params[:ext]}"
  end

  # Serve image tiles for progressive loading
  def tiles
    expires_in 10.years
    item = Item.find params[:item_id].to_i
    item.check_visibility_for current_user
    
    zoom = params[:zoom].to_f
    tile_x = params[:tile_x].to_i
    tile_y = params[:tile_y].to_i
    tile_size = params[:tile_size].to_i
    
    # Validate parameters
    return head :bad_request unless zoom > 0 && tile_size > 0
    
    # For now, we'll serve existing resized images as tiles
    # In a full implementation, you would generate actual tiles from the source image
    size = case zoom
           when 0...1.5
             'square'
           when 1.5...3.0
             'large'
           else
             'exploded'
           end
    
    # Generate tile from existing resized image
    tile_path = generate_tile(item, size, tile_x, tile_y, tile_size)
    
    if tile_path && File.exist?(tile_path)
      send_file tile_path, type: 'image/jpeg', disposition: 'inline'
    else
      # Fallback to regular resized image
      redirect_to "/data/resized/#{size}/#{item.id}-#{item.code}.jpg"
    end
  end

  def similar
    @item = Item.find params[:item_id].to_i
    @item.check_visibility_for current_user
    items = @item.similar_items
    if items
      render json: items, each_serializer: ItemSerializer, root: "items"
    else
      render json: { items: nil }
    end
  end

  private

  def items_params
    params.permit items: []
  end

  def item_tag_params
    params.permit items: [], tags: []
  end

  def generate_tile(item, size, tile_x, tile_y, tile_size)
    # Generate tile cache directory
    cache_dir = Rails.root.join('tmp', 'tiles', item.id.to_s, size)
    cache_dir.mkpath
    
    tile_filename = "#{tile_x}_#{tile_y}_#{tile_size}.jpg"
    tile_path = cache_dir.join(tile_filename)
    
    # Return cached tile if it exists
    return tile_path if tile_path.exist?
    
    # Path to the source resized image
    source_path = Rails.root.join('data', 'resized', size, "#{item.id}-#{item.code}.jpg")
    
    # Check if source image exists
    return nil unless source_path.exist?
    
    # Generate tile using ImageMagick
    # This is a simplified tile generation - in practice you'd want more sophisticated logic
    system("convert", source_path.to_s, 
           "-crop", "#{tile_size}x#{tile_size}+#{tile_x * tile_size}+#{tile_y * tile_size}",
           "+repage", 
           "-quality", "85",
           tile_path.to_s)
    
    tile_path.exist? ? tile_path : nil
  rescue => e
    Rails.logger.error "Error generating tile: #{e.message}"
    nil
  end
end
