class GenerateThumbsJob < ApplicationJob
  queue_as :default
  queue_with_priority 10

  SIZES = {
    :square => "200",
    :large => "1850x1000"
  }

  def perform item_id
    @item = Item.find item_id

    if @item.photo?
      generate_thumbs
    elsif @item.video?
      generate_video_stills
    end
  end

  private

  def generate_thumbs
    SIZES.each do |size,dim|
      dest = @item.resized_path size
      next if File.exist? dest

      build_thumb @item.full_path, dest, size
    end
  end

  def generate_video_stills
    need_generation = false
    SIZES.each do |size,dim|
      dest = @item.resized_path size
      next if File.exist?( dest )
      need_generation = true
    end

    return unless need_generation

    tmp = "/tmp/make-thumbs.#$$.#{rand(1_000_000)}"

    Dir.mkdir( tmp )
    tmp_file = "#{tmp}/snapshot.bmp"

    run "ffmpeg -v error -i #{se @item.full_path} -vsync 1 -vframes 1 -ss 2 -y #{se tmp_file}"
    if !File.exists?(tmp_file)
      warn "Error making thumbnail for #{@item.full_path}, trying at zero second mark"
      run "ffmpeg -v error -i #{se @item.full_path} -vsync 1 -vframes 1 -ss 0 -y #{se tmp_file}"
    end

    raise "Error making thumbnail for #{@item.full_path}" unless File.exists? tmp_file

    # Add filmstrip background
    filmstrip = "#{Rails.root}/app/assets/images/filmstrip.png"

    SIZES.each do |size,dim|
      dest = @item.resized_path size
      temp = "#{dest}.thumb.jpg"
      next if File.exist?( dest )

      build_thumb tmp_file, temp, size
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

  def build_thumb source, dest, size
    FileUtils.mkdir_p File.dirname( dest )

    image = MiniMagick::Image.open source
    image.format 'jpeg'
    temp = "#{dest}.#$$.jpg"
    image.combine_options do |c|
      c.auto_orient
      size_spec = SIZES[size]
      if size == :square
        size_spec = size_spec.to_i
        c.thumbnail "x#{size_spec*2}"
        c.resize "#{size_spec*2}x<"
        c.resize "50%"
        c.gravity "center"
        c.crop "#{size_spec}x#{size_spec}+0+0"
      else
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
end
