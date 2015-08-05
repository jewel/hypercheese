class CommentsController < ApplicationController
  respond_to :json

  # GET /comments
  def index
    @comments = Comment.where(item_id: params[:item_id].to_i).order( :created_at )
    render json: @comments
  end

  # POST /comments
  def create
    @item = Item.get params[:id]

    # If no account, tell user to log in and redirect user to the log in page.
    if !current_account
      flash[:error] = "You need to log in to make comments."
      redirect "/account/login"
    end

    email do
      from "cheese@tuxng.com"
      to "cheese@tuxng.com"
      subject "[Cheese] Comment on #{@item.id}"
      body "I hope you enjoy it."
    end

    c = Comment.new
    c.account = current_account
    c.item = @item
    c.created = Time.new
    c.text = params[:text]
    c.save

    flash[:notice] = "Comment saved"

    redirect url_for( :item_view, :id => @item.id )
  end
end
