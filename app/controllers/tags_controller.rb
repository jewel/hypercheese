class TagsController < ApplicationController
  def index
    @tags = Tag.all.order 'item_count desc'
    render json: @tags
  end

  def create
    render status: :created, json: Tag.create(tag_params)
  end

  def destroy
    render json: tag.destroy
  end

  def update
    @tag = tag
    @tag.update(tag_params)

    render json: @tag
  end

  private

  def tag_params
    p = params.dup
    p[:tag][:icon_item_id] = p[:tag][:icon]
    p.require(:tag).permit(:label, :icon_item_id)
  end

  def tag
    Tag.find(params[:id])
  end
end
