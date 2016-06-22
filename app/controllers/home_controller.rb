require_dependency 'activity'

class HomeController < ApplicationController
  def index
    render layout: "gallery"
  end

  def activity
    cache_path = Rails.root.join 'tmp/activities'
    json = {}
    if File.exists? cache_path
      json = JSON.parse File.binread(cache_path)
    end

    render json: json
  end
end
