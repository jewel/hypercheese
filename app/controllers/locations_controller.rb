class LocationsController < ApplicationController
  def index
    cache_path = Rails.root.join 'tmp/locations'
    cache_age = 24.hours

    # Check if cache exists and is fresh
    if File.exist?(cache_path) && File.mtime(cache_path) > cache_age.ago
      locations = JSON.parse File.binread(cache_path)
    else
      # Generate fresh data
      locations = Location.joins(item_locations: :item)
                         .where(items: { deleted: false, published: true })
                         .select('locations.*, COUNT(item_locations.item_id) as item_count')
                         .group('locations.id')
                         .order('item_count DESC')
                         .as_json(methods: [:item_count])

      # Cache the result
      tmp_path = "#{cache_path}.#$$.tmp"
      File.binwrite tmp_path, locations.to_json
      File.rename tmp_path, cache_path
    end

    render json: locations
  end
end
