require_dependency 'rtree'

class GeolocateJob < ApplicationJob
  def perform item_id
    item = Item.find item_id

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
    end
  end

  def load_geoindex
    cache = Rails.root + "db/geo.index"
    if cache.exist?
      puts "Loading cache"
      return Marshal.load File.open(cache.to_s, 'rb')
    end

    rtree = RTree.new
    Dir.glob("#{Rails.root}/db/geo/*json").sort.each do |path|
      puts "Loading #{path}"

      # Load the geojson file containing the world's administrative areas
      json = File.read path
      world = JSON.parse json

      shapes = RGeo::GeoJSON.decode world

      puts "Indexing #{shapes.size} shapes"
      shapes.each_with_index do |shape,index|
        begin
          puts " #{(index.to_f/shapes.size*100).round}%" if index % 4000 == 0
          rtree.insert rtree.root, shape
        rescue RGeo::Error::InvalidGeometry
          puts "Problem with shape: #$!"
        end
      end
    end
    temp = cache.to_s + ".#$$.tmp"
    Marshal.dump rtree, File.open(temp, 'wb')
    File.rename temp, cache.to_s
  end
end
