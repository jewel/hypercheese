class FindFacesJob < ApplicationJob
  FPS = 0.25
  SIZE = 256

  def perform item_id
    @item = Item.find item_id
    return if @item.face_count

    FileUtils.mkdir_p Rails.root + "public/data/faces"

    @item.face_count = 0

    Item.transaction do
      if @item.video?
        tmp = "/tmp/find-faces.#$$"
        FileUtils.rm_rf tmp
        Dir.mkdir tmp
        run "ffmpeg -v error -i #{se @item.full_path} -vsync 1 -vf fps=#{FPS} -y #{se tmp}/out%06d.png"
        files = Dir.glob "#{tmp}/*.png"
        files.sort.each_with_index do |path, index|
          find_faces path, index
        end
      elsif @item.photo?
        find_faces @item.full_path
      end
    end

    @item.save!
  end

  def find_faces path, index=nil
    res = post_image 'http://face:5000/detect', path

    if index
      # FFMPEG seems to be taking the middle frame out of the group
      timestamp = (index + 0.5) / FPS
    end

    res.each do |k,info|
      region = info[:facial_area]
      face = Face.create!(
        item: @item,
        position: info.to_json,
        timestamp: timestamp,
      )

      dest = face.path
      temp = "#{dest}.#$$.jpg"
      image = MiniMagick::Image.open path
      image.format 'jpeg'
      image.combine_options do |c|
        c.auto_orient
        c.crop "#{region[2] - region[0]}x#{region[3] - region[1]}+#{region[0]}+#{region[1]}"
        c.thumbnail "#{SIZE}x#{SIZE}>"
        c.colorspace 'sRGB'
        c.quality 88
      end
      image.write temp
      File.chmod 0644, temp
      File.rename temp, dest

      res = post_image 'http://face:5000/represent', dest
      raise "No embedding" unless res[:embedding]

      face.set_embedding res[:embedding]

      @item.face_count += 1
    end
  end
end
