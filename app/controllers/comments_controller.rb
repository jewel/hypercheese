class CommentsController < ApplicationController
  respond_to :json

  # POST /comments
  def create
    c = Comment.new
    c.update_attributes! comment_params
    c.user = current_user
    c.save!

    render json: c
  end

  def comment_params
    params.require(:comment).permit(:text, :item_id)
  end
end
