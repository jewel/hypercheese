require_dependency 'search'

class ItemsController < ApplicationController
  respond_to :json

  def index
    search = Search.new params[:query] || ''

    limit = params[:limit] || 1000
    offset = params[:offset] || 0

    res = search.items.limit( limit ).offset( offset )

    respond_with res, each_serializer: ItemSerializer, meta: { total: search.items.count }
  end

  def show
    respond_with item
  end

  def tags
    i = Item.find item_tag_params[:id].to_i
    i.tag_ids = item_tag_params[:tags]
    i.save
    respond_with i
  end

  private
  def item
    Item.find params[:id].to_i
  end

  def item_tag_params
    params.require(:item).permit(:id, tags: [])
  end

end
