class AlbumSharesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_approval!

  def show
    @album_share = AlbumShare.find_by_code(params[:share_id].to_s)
    return render_not_found unless @album_share
    
    @album = @album_share.album
    @items = @album.items_ordered

    @title = "#{@album.name} (#{@items.size} item#{@items.size == 1 ? '' : 's'})"
    
    @og_image = request.base_url + @items.first.resized_url(:large) if @items.any?

    render layout: 'share'
  end

  def items
    @album_share = AlbumShare.find_by_code(params[:share_id].to_s)
    return render_not_found unless @album_share
    
    @album = @album_share.album
    @items = @album.items_ordered.includes(:item_paths)

    render json: @items, each_serializer: SharedItemSerializer
  end

  def download
    @album_share = AlbumShare.find_by_code(params[:share_id].to_s)
    return render_not_found unless @album_share
    
    @album = @album_share.album
    download_zip @album.items_ordered
  end

  def download_item
    @album_share = AlbumShare.find_by_code(params[:share_id].to_s)
    return render_not_found unless @album_share
    
    @album = @album_share.album
    item = @album.items.find(params[:item_id].to_i)

    download_zip [item]
  end

  def upload
    @album_share = AlbumShare.find_by_code(params[:share_id].to_s)
    return render_not_found unless @album_share
    
    unless @album_share.allows_uploads
      render json: { error: 'Uploads not allowed for this album' }, status: :forbidden
      return
    end
    
    @album = @album_share.album
    
    # Handle file upload similar to existing upload logic
    # This would need to be integrated with the existing upload system
    
    render json: { success: true }
  end

  private

  def render_not_found
    render json: { error: 'Album share not found' }, status: :not_found
  end
end