require 'exifr'
require 'exifr/jpeg'

class LoadMetadataJob < ApplicationJob
  MAX_EXIF_VALUE_SIZE = 1024 # 1KB limit for EXIF values

  def perform item_id
    item = Item.find item_id
    return if item.deleted

    return if item.taken && item.width && item.height && (item.duration || item.variety == 'photo')

    path = item.full_path

    begin
      exif = EXIFR::JPEG.new path
      item.taken = exif.date_time_original if exif.date_time_original
      item.taken ||= exif.date_time_digitized if exif.date_time_digitized
      item.taken ||= exif.date_time if exif.date_time
      if exif.orientation.to_i > 4
        item.height = exif.width
        item.width = exif.height
      else
        item.height = exif.height
        item.width = exif.width
      end

      # Extract and store all EXIF data
      item.exif_data = extract_exif_data(exif)
    rescue
      warn "Import EXIF problem: #$!"
      metadata = read_exiftool path
      date = metadata['Create Date'] || metadata['Date/Time Original']
      zone = metadata['Timezone'] || metadata['Time Zone']

      if date !~ /^0000:/ && date =~ /^(\d\d\d\d):(\d\d):(\d\d) (.*)$/
        item.taken = DateTime.parse "#$1-#$2-#$3 #$4 #{zone}"
      end

      # Store exiftool metadata as EXIF data
      item.exif_data = filter_exif_data(metadata).to_json
    end

    if item.variety == 'photo'
      if !item.height
        item.width, item.height = MiniMagick::Image.open(path)[:dimensions]
      end
    elsif item.variety == 'video'
      data = Probe.video path
      item.width = data[:width]
      item.height = data[:height]
      item.duration = data[:duration]
    end

    item.taken ||= File.mtime path
    item.save!
  end

  private

  def extract_exif_data(exif)
    exif_hash = {}
    
    # Use introspection to get all available methods/data
    exif.class.instance_methods(false).each do |method|
      next if method.to_s.start_with?('_')
      next if [:initialize, :[], :each, :keys, :values].include?(method)
      
      begin
        value = exif.send(method)
        next if value.nil?
        
        # Convert to string for size checking
        value_str = value.to_s
        next if value_str.bytesize > MAX_EXIF_VALUE_SIZE
        
        exif_hash[method.to_s] = value
      rescue
        # Skip any methods that cause errors
      end
    end
    
    # Also try to get the raw EXIF data if available
    begin
      if exif.respond_to?(:to_hash)
        raw_data = exif.to_hash
        raw_data.each do |key, value|
          next if value.nil?
          value_str = value.to_s
          next if value_str.bytesize > MAX_EXIF_VALUE_SIZE
          
          exif_hash[key.to_s] = value
        end
      end
    rescue
      # Skip if to_hash fails
    end
    
    exif_hash.to_json
  end

  def filter_exif_data(metadata)
    filtered = {}
    metadata.each do |key, value|
      next if value.nil?
      value_str = value.to_s
      next if value_str.bytesize > MAX_EXIF_VALUE_SIZE
      
      filtered[key] = value
    end
    filtered
  end

  def read_exiftool path
    data = `exiftool -t #{se path}`
    raise "exiftool failed for #{path.inspect}" unless $? == 0
    metadata = {}
    data.split( /\n/ ).each do |line|
      row = line.split( /\t/, 2 )
      metadata[row.first] = row.last
    end
    metadata
  end
end
