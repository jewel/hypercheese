class ItemsController < ApplicationController
  respond_to :json

  def index
    respond_with Item.all
  end

  def show
    respond_with item
  end

  private
  def item
    Item.find params[:id].to_i
  end
end
