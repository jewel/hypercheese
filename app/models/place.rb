class Place < ActiveRecord::Base
  belongs_to :creator, class_name: 'User', foreign_key: 'created_by'
  has_many :item_places, dependent: :destroy
  has_many :items, through: :item_places

  validates :name, presence: true
  validates :latitude, presence: true, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, presence: true, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validates :radius, presence: true, numericality: { greater_than: 0 }

  after_create :associate_existing_items!
  after_update :update_item_associations!

  # Check if a coordinate is within this place's radius
  def contains_coordinate?(lat, lon)
    return false if lat.nil? || lon.nil?
    
    # Calculate distance using Haversine formula
    earth_radius = 6371.0 # km
    
    lat1_rad = latitude.to_f * Math::PI / 180
    lon1_rad = longitude.to_f * Math::PI / 180
    lat2_rad = lat.to_f * Math::PI / 180
    lon2_rad = lon.to_f * Math::PI / 180
    
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad
    
    a = Math.sin(dlat/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon/2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    
    distance = earth_radius * c * 1000 # convert to meters
    
    distance <= radius
  end

  # Find all places that contain a given coordinate
  def self.containing_coordinate(lat, lon)
    return none if lat.nil? || lon.nil?
    
    # For performance, first filter by a bounding box approximation
    # 1 degree of latitude is approximately 111 km
    # 1 degree of longitude varies by latitude, but we'll use a rough approximation
    lat_range = 0.01 # roughly 1.11 km
    lon_range = 0.01 # roughly 1.11 km at equator
    
    candidates = where(
      'latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?',
      lat - lat_range, lat + lat_range,
      lon - lon_range, lon + lon_range
    )
    
    # Then check each candidate precisely
    candidates.select { |place| place.contains_coordinate?(lat, lon) }
  end

  # Update item associations when place coordinates change
  def update_item_associations!
    return unless saved_change_to_latitude? || saved_change_to_longitude? || saved_change_to_radius?
    
    # Remove system-added associations that are no longer valid
    item_places.where(user_id: nil).includes(:item).each do |item_place|
      unless contains_coordinate?(item_place.item.latitude, item_place.item.longitude)
        item_place.destroy
      end
    end
    
    # Add new associations for items within the updated area
    Item.where.not(latitude: nil, longitude: nil).find_each do |item|
      if contains_coordinate?(item.latitude, item.longitude)
        # Only add if not already associated
        unless item_places.exists?(item_id: item.id)
          item_places.create!(item_id: item.id, created_at: Time.current)
        end
      end
    end
  end

  # Associate items when place is created
  def associate_existing_items!
    Item.where.not(latitude: nil, longitude: nil).find_each do |item|
      if contains_coordinate?(item.latitude, item.longitude)
        item_places.find_or_create_by(item_id: item.id) do |ip|
          ip.created_at = Time.current
        end
      end
    end
  end
end