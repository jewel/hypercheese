class LocationsController < ApplicationController
  def index
    # Get all locations with photo counts, excluding deleted items and only published items
    locations = Location.joins(item_locations: :item)
                       .where(items: { deleted: false, published: true })
                       .select('locations.*, COUNT(item_locations.item_id) as photo_count')
                       .group('locations.id')
                       .order('photo_count DESC')
    
    render json: locations.as_json(methods: [:photo_count])
  end
end