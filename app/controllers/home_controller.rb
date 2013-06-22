class HomeController < ApplicationController
  def index
    @events = Event.order( "start DESC" ).page( params[:page] ).per(50)
  end
end
