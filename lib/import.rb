require 'exifr'
require 'digest/md5'
require 'shellwords'

module Import
  EXTS = {
    'jpg' => 'photo',
    'jpeg' => 'photo',
    'tiff' => 'photo',
    'tif' => 'photo',
    'avi' => 'video',
    'mov' => 'video',
    'mpg' => 'video',
  }

  def self.check_dependencies
    check_prog 'identify', 'imagemagick'
    check_prog 'jpegtran', 'libjpeg-turbo-progs'
  end

  def self.by_path path
    path = File.absolute_path( path )

    if Object.const_defined? :EXCLUDE_REGEX
      EXCLUDE_REGEX.each do |regex|
        return nil if path =~ regex
      end
    end

    raise "Strange path #{path.inspect}" unless path =~ /\.(\w+)\Z/
    ext = $1.downcase

    variety = EXTS[ext]
    raise "File extension not supported" unless variety

    partial_path = path.sub "#{File.absolute_path(Item::BASE_PATH)}/", ''
    raise "File is not in #{Item::BASE_PATH}" unless partial_path != path

    old = Item.where( :path => partial_path ).first
    if old
      item = old
    else
      md5 = Digest::MD5.file( path ).hexdigest

      old = Item.where( :md5 => md5 ).first
      raise "Already exists by md5:  #{old.id}" if old

      puts "Creating #{partial_path}"

      item = Item.new

      item.path = partial_path

      item.md5 = md5

      item.variety = variety

      load_exif_data item

      date = item.taken.to_date
      event = Event.where( [ "DATE( start ) = ?", date ] ).first

      event ||= Event.create({
        name: nil,
        start: item.taken.strftime( "%Y-%m-%d" ),
        finish: item.taken.strftime( "%Y-%m-%d" ),})

      item.event = event

      item.save
    end

    if variety == 'photo'
      generate_resized item
    else
      generate_video_stills item
      generate_video_stream item
    end

    item
  end

  SIZES = {
    # :small => "250x250",
    :square => "200",
    :large => "1850x1000"
  }

  def self.generate_resized item
    SIZES.each do |size,dim|
      dest = item.resized_path size
      next if File.exist?( dest )

      puts "Building #{item.full_path} thumb size #{size}"

      build_thumb item.full_path, dest, size
    end
  end

  def self.load_exif_data item
    item.taken = File.mtime item.full_path
    begin
      exif = EXIFR::JPEG.new item.full_path
      item.taken = exif.date_time if exif.date_time
      if exif.orientation.to_i > 4
        item.height = exif.width
        item.width = exif.height
      else
        item.height = exif.height
        item.width = exif.width
      end
    rescue
      warn "Import EXIF problem: #$!"
    end
  end

  private
  def self.run( *a )
    puts "[import] " + a.join( ' ' )
    system( *a ) or raise "Could not run #{a.join( ' ' )}"
    $? == 0 or raise "Failed command"
  end

  def self.check_prog executable, package
    `command -v #{executable}`
    raise "The program '#{executable}' is missing.  Install the #{package} package" unless $?.success?
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

    tmp = "/tmp/make-thumbs.#$$"

    Dir.mkdir( tmp )

    run( "mplayer",
           "-ao", "null",
           "-vo", "png:outdir=#{tmp}",
           "-ss", "2",
           "-frames", "1",
           "-really-quiet",
           item.full_path )

    tmp_file = "#{tmp}/00000001.png"
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
      run( "composite", "-resize", "#{dim}!", filmstrip, temp, dest )

      File.unlink temp

      raise "Could not composite video frame" unless File.exist? dest
    end

    File.unlink tmp_file
    Dir.rmdir tmp
  end

  def self.build_thumb source, dest, size, rotation=nil
    FileUtils.mkdir_p File.dirname( dest )

    image = MiniMagick::Image.open source
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
      c.quality "88"
    end
    image.format 'jpeg'
    image.write temp
    if size == :large
      run( "jpegtran -progressive #{temp} > #{temp}P" )
      File.unlink temp
      File.rename temp + "P", dest
    else
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

  VIDEO_TYPES = [ 'ogv', 'mp4' ]

  def self.generate_video_stream item
    path = item.full_path

    need_encoding = false
    VIDEO_TYPES.each do |type|
      next if File.exists?( item.video_stream_path type )
      need_encoding = true
    end

    return unless need_encoding

    rotation = read_rotation path

    tmp_rotated = "/tmp/#{item.id}.rotated.avi"

    dimension = "height"
    size = 480

    if rotation
      raise "Not yet supported" if rotation == 180

      dimension = "width"

      r = 1
      r = 2 if rotation == 270

      run( "mencoder", "-vf", "rotate=#{r}", "-oac", "copy", "-ovc", "lavc", "-lavcopts", "vcodec=ljpeg", "-o", tmp_rotated, path )

      path = tmp_rotated
    end

    VIDEO_TYPES.each do |type|
      dest = item.video_stream_path type
      next if File.exist? dest
      FileUtils.mkdir_p File.dirname( dest )
      tmp = "#{dest}.tmp"
      if type == 'mp4'
        cmd = %w{
          HandBrakeCLI -v -O -e x264 -b 2000 -E faac -6 mono -B 128
          -R Auto -f mp4 -2 -T -x ref=3:bframes=2:me=umh
        }
        cmd += [ "--#{dimension}", size.to_s ]
        cmd += [ '-i', path, '-o', tmp ]
        run( *cmd )
      elsif type =='ogv'
        tmp2 = "#{tmp}.mkv"
        cmd = %w{
          HandBrakeCLI -v -O -e theora -b 2000 -E vorbis -6 mono -B 128 -R 22050 -f mkv -2 -T
        }
        cmd += [ "--#{dimension}", size.to_s ]
        cmd += [ '-i', path, '-o', tmp2 ]
        run( *cmd )

        # Put into ogg container instead of mkv

        video = "#{tmp}.video"
        audio = "#{tmp}.audio"
        run( "mkvextract", "tracks", tmp2, "1:#{video}", "2:#{audio}" )

        run( "oggz-merge", "-o", tmp, video, audio )
        File.unlink audio
        File.unlink video
      end

      File.rename tmp, dest
    end

    File.unlink tmp_rotated if File.exist?( tmp_rotated )
  end
end
