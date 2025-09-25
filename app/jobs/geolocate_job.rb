require_dependency 'r_tree'
require 'csv'

class GeolocateJob < ApplicationJob
  @@rtree = nil
  @@country_codes = nil

  def perform item_id
    item = Item.find item_id
    return if item.deleted

    # FIXME we need a way to note that a photo has no location information
    return if ItemLocation.where(item_id: item.id).exists?

    rtree = load_geoindex

    factory = RGeo::Geographic.simple_mercator_factory

    Item.transaction do
      exif = item.exif

      # Load the photo and extract the GPS coordinates
      return unless exif
      return unless exif.gps
      latitude = exif.gps.latitude
      longitude = exif.gps.longitude
      item.latitude = latitude
      item.longitude = longitude
      item.save!

      # Create a point object representing the location of the photo
      point = factory.point longitude.to_f, latitude.to_f

      # Iterate over all the features in the geojson file to find the ones
      # containing the photo's location
      matches = rtree.query rtree.root, point
      matches.each do |shape|
        name = shape[:shapeName] || shape[:NAME] || shape[:shapeGroup]
        geoid = shape[:shapeID] || shape[:GEOID] || shape[:shapeGroup]
        raise "No geoid for #{shape.properties.inspect}" if geoid.blank?
        raise "No name for #{shape.properties.inspect}" if name.blank?

        # Replace three-character country codes with full country names
        if geoid.match?(/\A[A-Z]{3}\z/)
          country_name = load_country_codes[geoid]
          name = country_name if country_name
        end

        location = Location.find_by_geoid geoid
        if location && location.name != name
          raise "Multiple locations for #{geoid.inspect}"
        end
        if !location
          location = Location.create!({
            name: name,
            geoid: geoid,
            properties: shape.properties.to_json,
          })
        end
        ItemLocation.create! item_id: item.id, location_id: location.id
      end

      # Also assign places based on GPS coordinates
      item.assign_places!
    end
  end

  def load_geoindex
    return @@rtree if @@rtree
    cache = Rails.root + "db/geo.index/rtree"
    raise "geo index has not been built (run script/build-geo-index)" unless cache.exist?
    @@rtree = Marshal.load cache.open 'rb'
    @@rtree
  end

  def load_country_codes
    return @@country_codes if @@country_codes
    csv_path = Rails.root + "db/geo/wikipedia-iso-country-codes.csv"
    @@country_codes = {}

    CSV.foreach csv_path, headers: true do |row|
      alpha3 = row['Alpha-3 code']
      country_name = row['English short name lower case']
      @@country_codes[alpha3] = country_name if alpha3 && country_name
    end

    @@country_codes
  end
end
