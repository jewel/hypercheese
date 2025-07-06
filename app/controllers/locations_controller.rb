class LocationsController < ApplicationController
  respond_to :json

  def search
    query = params[:q]
    
    if query && query.length > 2
      # Search locations by name using LIKE query
      locations = Location.where("name LIKE ?", "%#{query}%")
                         .limit(10)
                         .order(:name)
      
      results = locations.map do |location|
        # Parse properties JSON to get bounds if available
        properties = JSON.parse(location.properties) rescue {}
        
        # Calculate bounds from properties if available
        bounds = nil
        if properties['bounds']
          bounds = properties['bounds']
        elsif properties['geometry']
          # For polygons, calculate bounds from coordinates
          geometry = properties['geometry']
          if geometry['type'] == 'Polygon' && geometry['coordinates']
            coords = geometry['coordinates'].first
            lats = coords.map { |c| c[1] }
            lngs = coords.map { |c| c[0] }
            bounds = [
              [lats.min, lngs.min],
              [lats.max, lngs.max]
            ]
          end
        end
        
        {
          id: location.id,
          name: location.name,
          geoid: location.geoid,
          bounds: bounds
        }
      end
      
      render json: results
    else
      render json: []
    end
  end
end