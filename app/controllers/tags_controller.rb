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

  private

  def tag_params
    params.require(:tag).permit(:label)
  end

  def tag
    Tag.find(params[:id])
  end
end
