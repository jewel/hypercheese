class SharesController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:show, :download]
  skip_before_filter :verify_approval!, only: [:show, :download]

  def show
    @share = Share.find_by_code params[:id]
    @items = @share.items

    @title = "#{@items.size} Picture#{@items.size == 1 ? '' : 's'}"

    @og_image = request.base_url + @items.first.resized_url(:large)

    render layout: 'share'
  end

  def items
    @share = Share.find_by_code params[:share_id]
    @items = @share.items

    render json: @items, each_serializer: SharedItemSerializer
  end

  def download
    @share = Share.find_by_code params[:share_id]
    download_zip @share.items
  end
end
