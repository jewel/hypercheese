class HomeController < ApplicationController
  def index
    render layout: "gallery"
  end
end
