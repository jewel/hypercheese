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

  def update_date
    require_write!

    @item = Item.find params[:item_id].to_i
    @item.check_visibility_for current_user
    
    fuzzy_date = params[:fuzzy_date]
    precise_date = parse_fuzzy_date(fuzzy_date)
    
    @item.fuzzy_date = fuzzy_date
    @item.taken = precise_date
    @item.save!

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

  def parse_fuzzy_date(fuzzy_date)
    return nil if fuzzy_date.blank?
    
    # Extract postfix (e.g., "1985 #3" -> ["1985", "3"])
    postfix = 0
    date_part = fuzzy_date.strip
    if date_part =~ /^(.+)\s+#(\d+)$/
      date_part = $1.strip
      postfix = $2.to_i
    end
    
    # Parse different date formats
    case date_part
    when /^\d{4}s$/ # Decade format like "1980s"
      decade = date_part.to_i
      DateTime.new(decade, 1, 1, 0, 0, postfix)
    when /^\d{4}$/ # Year format like "1985"
      year = date_part.to_i
      DateTime.new(year, 1, 1, 0, 0, postfix)
    when /^\d{4}-\d{2}$/ # Month format like "1985-03"
      year, month = date_part.split('-').map(&:to_i)
      DateTime.new(year, month, 1, 0, 0, postfix)
    when /^\d{4}-\d{2}-\d{2}$/ # Day format like "1985-03-15"
      year, month, day = date_part.split('-').map(&:to_i)
      DateTime.new(year, month, day, 0, 0, postfix)
    when /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/ # Full datetime format
      DateTime.parse(date_part) + postfix.seconds
    else
      # Try to parse as a full date string
      DateTime.parse(date_part) + postfix.seconds
    end
  rescue ArgumentError => e
    # If parsing fails, return nil
    nil
  end
end
