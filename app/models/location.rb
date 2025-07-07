class Location < ActiveRecord::Base
  has_many :events
  has_many :item_locations
  has_many :items, through: :item_locations

  def item_count
    @item_count || item_locations.count
  end

  def item_count=(count)
    @item_count = count
  end
end
