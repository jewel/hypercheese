class HomeController < ApplicationController
  def index
    @by_event = Hash.new { |h,k| h[k] = [] }
    pos = 0
    while @by_event.size < 100
      res = Item.order('taken desc').offset(pos).limit(1000)
      need_count = true
      res.each do |item|
        need_count = false
        @by_event[item.event].push item
      end
      if need_count
        break if res.count == 0
      end
      pos += 1000
    end
  end
end
