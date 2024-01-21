require 'exifr'
require 'exifr/jpeg'

class LoadMetadataJob < ApplicationJob
  def perform item_id
    item = Item.find item_id

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
    rescue
      warn "Import EXIF problem: #$!"
      metadata = read_exiftool path
      date = metadata['Create Date'] || metadata['Date/Time Original']
      zone = metadata['Timezone'] || metadata['Time Zone']

      if date !~ /^0000:/ && date =~ /^(\d\d\d\d):(\d\d):(\d\d) (.*)$/
        item.taken = DateTime.parse "#$1-#$2-#$3 #$4 #{zone}"
      end
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
