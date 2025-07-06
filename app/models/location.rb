class Location < ActiveRecord::Base
  has_many :events
  has_many :item_locations
  has_many :items, through: :item_locations

  def photo_count
    @photo_count || item_locations.count
  end

  def photo_count=(count)
    @photo_count = count
  end
end
