class AlbumsController < ApplicationController
  respond_to :json

  def index
    @albums = Album.includes(:user, :album_items).order(:name)
    render json: @albums, each_serializer: AlbumSerializer
  end

  def show
    @album = Album.includes(:items, :user).find(params[:id])
    render json: @album, serializer: AlbumSerializer, include: 'items'
  end

  def create
    require_write!
    
    @album = current_user.albums.build(album_params)
    
    if @album.save
      render json: @album, serializer: AlbumSerializer
    else
      render json: { errors: @album.errors }, status: :unprocessable_entity
    end
  end

  def update
    require_write!
    
    @album = Album.find(params[:id])
    
    # Check if user owns the album
    if @album.user != current_user
      render json: { error: 'Not authorized' }, status: :forbidden
      return
    end
    
    if @album.update(album_params)
      render json: @album, serializer: AlbumSerializer
    else
      render json: { errors: @album.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    require_write!
    
    @album = Album.find(params[:id])
    
    # Check if user owns the album
    if @album.user != current_user
      render json: { error: 'Not authorized' }, status: :forbidden
      return
    end
    
    @album.destroy
    head :no_content
  end

  def add_items
    require_write!
    
    @album = Album.find(params[:album_id])
    
    # Check if user owns the album
    if @album.user != current_user
      render json: { error: 'Not authorized' }, status: :forbidden
      return
    end
    
    item_ids = params[:item_ids].map(&:to_i)
    items = Item.where(id: item_ids)
    
    # Check visibility for all items
    items.each { |item| item.check_visibility_for current_user }
    
    Album.transaction do
      items.each do |item|
        @album.album_items.find_or_create_by(item: item) do |album_item|
          album_item.added_by = current_user
        end
      end
    end
    
    @album.reload
    render json: @album, serializer: AlbumSerializer, include: 'items'
  end

  def remove_item
    require_write!
    
    @album = Album.find(params[:album_id])
    
    # Check if user owns the album
    if @album.user != current_user
      render json: { error: 'Not authorized' }, status: :forbidden
      return
    end
    
    item_id = params[:item_id].to_i
    album_item = @album.album_items.find_by(item_id: item_id)
    
    if album_item
      album_item.destroy
    end
    
    @album.reload
    render json: @album, serializer: AlbumSerializer, include: 'items'
  end

  def share
    require_write!
    
    @album = Album.find(params[:album_id])
    
    # Check if user owns the album
    if @album.user != current_user
      render json: { error: 'Not authorized' }, status: :forbidden
      return
    end
    
    allows_uploads = params[:allows_uploads] == 'true'
    
    @album_share = @album.album_shares.create!(allows_uploads: allows_uploads)
    
    url = "#{request.protocol}#{request.host_with_port}/album_shares/#{@album_share.code}"
    
    render json: { url: url }
  end

  def user_albums
    albums = current_user.albums
                        .includes(:album_items)
                        .recently_updated
                        .limit(20)
    
    render json: albums, each_serializer: AlbumSerializer
  end

  private

  def album_params
    params.require(:album).permit(:name, :description)
  end
end