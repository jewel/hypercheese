class SharesController < ApplicationController
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_approval!

  def show
    @share = Share.find_by_code params[:id].to_s
    @items = @share.items

    @title = "#{@items.size} Picture#{@items.size == 1 ? '' : 's'}"

    @og_image = request.base_url + @items.first.resized_url(:large)

    render layout: 'share'
  end

  def items
    @share = Share.find_by_code params[:share_id].to_s
    @items = @share.items.includes(:item_paths)

    render json: @items, each_serializer: SharedItemSerializer
  end

  def download
    @share = Share.find_by_code params[:share_id].to_s
    download_zip @share.items
  end

  def download_item
    @share = Share.find_by_code params[:share_id].to_s
    item = @share.items.find params[:item_id].to_i

    download_zip [item]
  end
end
