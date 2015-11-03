class TagsController < ApplicationController
  def index
    @tags = Tag.all.order 'item_count desc'
    render json: @tags
  end

  def create
    render status: :created, json: Tag.create(tag_params)
  end

  private

  def tag_params
    params.require(:tag).permit(:label)
  end
end
