class CommentsController < ApplicationController
  respond_to :json

  # GET /comments
  def index
    @comments = Comment.where(item_id: params[:item_id].to_i).order( :created_at )
    render json: @comments
  end

  # GET /comments/:id
  def show
    @comment = Comment.find params[:id]
    render json: @comment
  end

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
