class HomeController < ApplicationController
  def index
    @by_event = Hash.new { |h,k| h[k] = [] }
    Item.order('taken desc').limit(100).each do |item|
      @by_event[item.event].push item
    end
  end
end
