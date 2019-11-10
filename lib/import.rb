require 'exifr'
require 'digest/md5'
require 'pathname'
require 'shellwords'
require_relative 'probe'
require_relative 'scaler'
require 'exifr/jpeg'

module Import
  EXTS = {
    'jpg' => 'photo',
    'jpeg' => 'photo',
    'tiff' => 'photo',
    'tif' => 'photo',
    'png' => 'photo',
    'avi' => 'video',
    'mov' => 'video',
    'mpg' => 'video',
    'mts' => 'video',
    'mp4' => 'video',
    'mkv' => 'video',
    'vob' => 'video',
    'dv' => 'video',
  }

  def self.check_dependencies
    check_prog 'identify', 'imagemagick'
    check_prog 'jpegtran', 'libjpeg-turbo-progs'
  end

  def self.by_path path
    path = Pathname.new( path ).cleanpath.to_s
    path = File.join Dir.pwd, path unless path =~ /\A\//

    if Object.const_defined? :EXCLUDE_REGEX
      EXCLUDE_REGEX.each do |regex|
        if path =~ regex
          warn "Excluding #{path.inspect} due to #{regex.inspect}"
          return nil
        end
      end
    else
      warn "Not excluding private files, no EXCLUDE REGEX defined" unless @warned
      @warned = true
    end

    raise "Strange path" unless path =~ /\.(\w+)\Z/
    ext = $1.downcase

    type = EXTS[ext]
    raise "File extension not supported" unless type
    raise "Empty file" unless File.size(path) > 0

    normalized_path = path.delete_prefix ItemPath::BASE_PATH + "/"
    partial_path = normalized_path.sub %r{\A(.*?)/}, ''
    source_path = $1
    source = Source.find_by_path source_path
    raise "No source set up for #{source_path}" unless source

    old = ItemPath.where(source: source).where( path: partial_path ).first
    if old
      item = old.item
      warn "Item already imported: #{partial_path}"
      if partial_path != old.path
        # MySQL case sensitivity issues
        warn "Case sensitivity problem: #{old.path.inspect} -> #{partial_path.inspect}"
      end

      load_metadata item, path, type
      item.save
    else
      md5 = Digest::MD5.file( path ).hexdigest

      old = Item.where( :md5 => md5 ).first
      if old
        old.paths.each do |item_path|
          next if File.exists? item_path.full_path
          warn "Alternate path #{item_path.path} no longer exists!"
          item_path.destroy
        end
        warn "#{partial_path} has same MD5 as #{old.paths.size} other files"
        item_path = ItemPath.new item: old, source: source, path: partial_path
        item_path.save

        return
      end
      warn "Creating #{partial_path}"

      item = Item.new

      if source.user_id
        item.published = nil
      end

      item.md5 = md5

      item.variety = type
      item.code = SecureRandom.urlsafe_base64 8

      load_metadata item, path, type
      item.taken ||= File.mtime path

      date = item.taken.to_date
      event = Event.where( [ "DATE( start ) = ?", date ] ).first

      event ||= Event.create({
        name: nil,
        start: item.taken.strftime( "%Y-%m-%d" ),
        finish: item.taken.strftime( "%Y-%m-%d" ),
      })

      item.event = event

      item.save

      item_path = ItemPath.new( item: item, source: source, path: partial_path )
      item_path.save
    end

    generate_resized item

    item
  end

  def self.generate_resized item
    if item.variety == 'photo'
      generate_thumbs item
    else
      generate_video_stills item
      generate_video_exploded item
      generate_video_stream item
    end

    item
  end

  SIZES = {
    :square => "200",
    :large => "1850x1000"
  }

  def self.generate_thumbs item
    SIZES.each do |size,dim|
      dest = item.resized_path size
      next if File.exist?( dest )

      puts "Building #{item.full_path} thumb size #{size}"

      build_thumb item.full_path, dest, size
    end
  end

  def self.load_metadata item, path, type
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
      zone = metadata['Timezone']

      if date !~ /^0000:/ && date =~ /^(\d\d\d\d):(\d\d):(\d\d) (.*)$/
        item.taken = DateTime.parse "#$1-#$2-#$3 #$4 #{zone}"
      end
    end
    if !item.height
      if type == 'photo'
        item.width, item.height = MiniMagick::Image.open(path)[:dimensions]
      else
        data = Probe.video path
        item.width = data[:width]
        item.height = data[:height]
      end
    end
  end

  private
  def self.run cmd
    puts "[import] " + cmd
    system( cmd ) or raise "Could not run #{cmd}"
    $? == 0 or raise "Failed command"
  end

  def self.read_exiftool path
    data = `exiftool -t #{se path}`
    raise "exiftool failed for #{path.inspect}" unless $? == 0
    metadata = {}
    data.split( /\n/ ).each do |line|
      row = line.split( /\t/, 2 )
      metadata[row.first] = row.last
    end
    metadata
  end

  def self.generate_video_exploded item
    dest = item.resized_path :exploded
    return if File.exists? dest

    puts "Generated Exploded for #{item.full_path}"
    tmp = "/tmp/make-exploded.#$$.#{rand 1_000_000}"

    Dir.mkdir tmp
    info = Probe.video item.full_path
    target_w, target_h = [1920, 1080]
    if info[:width] < info[:height]
      target_w, target_h = [target_h, target_w]
    end

    total_w, total_h = Scaler.scale info[:width], info[:height], target_w, target_h

    # Have a frame about every three seconds
    target_frame_count = info[:duration] / 3

    # But round to the nearest square
    grid_w = Math.sqrt(target_frame_count).round
    grid_w = 1 if grid_w < 1
    grid_h = grid_w

    thumb_w = (total_w / grid_w).round
    thumb_h = (total_h / grid_h).round

    total = grid_w * grid_h
    gap = info[:duration] / total
    warn "gap will be #{gap.inspect}"

    run "ffmpeg -v error -i #{se item.full_path} -vsync 1 -vf fps=#{1.0/gap} -vframes #{total} -s #{thumb_w}x#{thumb_h} -y #{se tmp}/out%06d.bmp"

    run "montage #{se tmp}/*.bmp -geometry #{thumb_w}x#{thumb_h}+0+0 -tile #{grid_w}x#{grid_h} #{se tmp}/grid.jpg"
    FileUtils.mkdir_p File.dirname( dest )
    FileUtils.move "#{tmp}/grid.jpg", dest
    run "rm -r #{se tmp}"
  end


  def self.generate_video_stills item
    need_generation = false
    SIZES.each do |size,dim|
      dest = item.resized_path size
      next if File.exist?( dest )
      need_generation = true
    end

    return unless need_generation

    puts "Generating stills for #{item.full_path}"

    tmp = "/tmp/make-thumbs.#$$.#{rand(1_000_000)}"

    Dir.mkdir( tmp )
    tmp_file = "#{tmp}/snapshot.bmp"

    run "ffmpeg -v error -i #{se item.full_path} -vsync 1 -vframes 1 -ss 2 -y #{se tmp_file}"
    if !File.exists?(tmp_file)
      warn "Error making thumbnail for #{item.full_path}, trying at zero second mark"
      run "ffmpeg -v error -i #{se item.full_path} -vsync 1 -vframes 1 -ss 0 -y #{se tmp_file}"
    end

    raise "Error making thumbnail for #{item.full_path}" unless File.exists? tmp_file

    rotation = read_rotation item.full_path

    image = MiniMagick::Image.open tmp_file
    switch = rotation && ( rotation == 90 || rotation == 270 )

    if switch
      item.width = image[:height]
      item.height = image[:width]
    else
      item.width = image[:width]
      item.height = image[:height]
    end
    item.save

    # Add filmstrip background
    filmstrip = "#{Rails.root}/app/assets/images/filmstrip.png"

    SIZES.each do |size,dim|
      dest = item.resized_path size
      temp = "#{dest}.thumb.jpg"
      next if File.exist?( dest )

      build_thumb tmp_file, temp, size, rotation
      dim = "#{dim}x#{dim}" unless dim =~ /x/

      # Minimagick doesn't do composite very well
      run "composite -resize #{se dim}! #{se filmstrip} #{se temp} #{se dest}"

      File.unlink temp

      raise "Could not composite video frame" unless File.exist? dest
      File.chmod 0644, dest
    end

    File.unlink tmp_file
    Dir.rmdir tmp
  end

  def self.build_thumb source, dest, size, rotation=nil
    FileUtils.mkdir_p File.dirname( dest )

    image = MiniMagick::Image.open source
    image.format 'jpeg'
    temp = "#{dest}.#$$.jpg"
    image.combine_options do |c|
      if rotation
        c.rotate rotation
      else
        c.auto_orient
      end
      size_spec = SIZES[size]
      if size == :square
        size_spec = size_spec.to_i
        c.thumbnail "x#{size_spec*2}"
        c.resize "#{size_spec*2}x<"
        c.resize "50%"
        c.gravity "center"
        c.crop "#{size_spec}x#{size_spec}+0+0"
      else
        # The '>' flag means to never enlarge
        c.thumbnail size_spec
      end
      c.trim
      c.colorspace 'sRGB'
      c.quality 88
    end
    image.write temp
    if size == :large
      run "jpegtran -progressive #{se temp} > #{se temp}P"
      File.unlink temp
      File.chmod 0644, temp + "P"
      File.rename temp + "P", dest
    else
      File.chmod 0644, temp
      File.rename temp, dest
    end
  end

  def self.read_rotation path
    rotation_file = "#{path}.rotate"
    if File.exist? rotation_file
      return IO.read( rotation_file ).to_i
    end
    nil
  end

  def self.generate_video_stream item
    path = item.full_path

    dest = item.video_stream_path
    return if File.exists? dest

    rotation = read_rotation path

    dimension = "height"

    if rotation && rotation != 0
      raise "Rotation not yet supported"
    end

    FileUtils.mkdir_p File.dirname( dest )
    tmp = "#{dest}.tmp"

    info = Probe.video path
    height = [720, info[:height]].min
    rate = [60, info[:rate]].min

    run "ffmpeg -v error -i #{se path} -pass 1 -passlogfile /tmp/ffmpegfirstpass.#$$.log -preset veryslow -b:v 3000k -strict experimental -vf scale=-2:#{height} -r #{rate} -an -vcodec libx264 -pix_fmt yuv420p -f mp4 -y /dev/null"
    run "ffmpeg -v error -i #{se path} -pass 2 -passlogfile /tmp/ffmpegfirstpass.#$$.log -preset veryslow -b:v 3000k -b:a 128k -ar 48000 -strict experimental -vf scale=-2:#{height} -r #{rate} -acodec aac -vcodec libx264 -pix_fmt yuv420p -f mp4 -y #{se tmp}"

    File.chmod 0644, tmp
    File.rename tmp, dest
  end

  def self.se str
    Shellwords.shellescape str
  end
end
