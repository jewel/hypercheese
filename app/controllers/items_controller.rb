class ItemsController < ApplicationController
  respond_to :json

  def index
    limit = params[:limit]
    offset = params[:offset]

    if !limit
      limit = 2
    end
    if !offset 
      offset = 0
    end

    respond_with Item.all.limit(limit).offset(offset), meta: { total:Item.all.count}
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
