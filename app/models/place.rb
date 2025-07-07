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
  def contains_coordinate? lat, lon
    return false if lat.nil? || lon.nil?

    factory = RGeo::Geographic.spherical_factory srid: 4326
    place_point = factory.point longitude, latitude
    target_point = factory.point lon, lat

    distance_meters = place_point.distance target_point

    distance_meters <= radius
  end

  # Find all places that contain a given coordinate
  def self.containing_coordinate lat, lon
    return none if lat.nil? || lon.nil?

    all.select { |place| place.contains_coordinate?(lat, lon) }
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

  def associate_existing_items!

    # This does not wrap around the date line
    min_lat = latitude - radius / 111_111
    max_lat = latitude + radius / 111_111

    # This does not work at the poles.
    lat_radians = latitude * Math::PI / 180
    min_lon = longitude - radius / 111_111 / Math.cos(lat_radians)
    max_lon = longitude + radius / 111_111 / Math.cos(lat_radians)

    # Query items within bounding box first
    candidates = Item.where.not(latitude: nil, longitude: nil)
                     .where("latitude >= ? AND latitude <= ? AND longitude >= ? AND longitude <= ?",
                           min_lat, max_lat, min_lon, max_lon)

    # Then filter candidates with precise distance calculation
    candidates.find_each do |item|
      if contains_coordinate?(item.latitude, item.longitude)
        item_places.find_or_create_by(item_id: item.id) do |ip|
          ip.created_at = Time.current
        end
      end
    end
  end
end
