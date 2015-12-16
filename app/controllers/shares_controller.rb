class SharesController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:show, :download]
  skip_before_filter :verify_approval!, only: [:show, :download]

  def show
    @share = Share.find_by_code( params[:id] )
    @items = @share.items

    @has_video = false
    @items.each do |item|
      @has_video = true if item.variety == "video"
    end

    render layout: 'share'
  end

  def download
    @share = Share.find_by_code( params[:share_id] )
    download_zip @share.items
  end

  def create
    code = SecureRandom.urlsafe_base64 8

    Share.transaction do
      share = Share.new
      share.user = current_user
      share.code = code
      share.save

      items_params[:items].each do |item_id|
        ShareItem.create share: share, item_id: item_id
      end
    end

    url = "#{request.protocol}#{request.host_with_port}/shares/#{code}"

    render json: { url: url }
  end

  private

  def items_params
    params.permit items: []
  end
end
