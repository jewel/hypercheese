class FindFacesJob < ApplicationJob
  FPS = 0.25  # Still used for embedding generation
  DETECTION_FPS = 30  # Detect faces every frame (assuming 30fps video)
  SIZE = 256
  TRAIL_DISTANCE_THRESHOLD = 50  # pixels
  TRAIL_TIME_THRESHOLD = 2.0  # seconds

  def perform item_id
    @item = Item.find item_id
    return if @item.deleted
    return if @item.face_count

    FileUtils.mkdir_p Rails.root + "public/data/faces"

    @item.face_count = 0

    Item.transaction do
      if @item.video?
        detect_faces_in_video
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
      face.save!

      @item.face_count += 1
    end
  end

  def detect_faces_in_video
    # Extract frames for every frame detection
    tmp_detection = "/tmp/find-faces-detection.#$$"
    tmp_embedding = "/tmp/find-faces-embedding.#$$"
    
    FileUtils.rm_rf tmp_detection
    FileUtils.rm_rf tmp_embedding
    Dir.mkdir tmp_detection
    Dir.mkdir tmp_embedding
    
    # Extract frames at high framerate for position tracking
    run "ffmpeg -v error -i #{se @item.full_path} -vsync 1 -vf fps=#{DETECTION_FPS} -y #{se tmp_detection}/frame%06d.bmp"
    
    # Extract frames at low framerate for embedding generation
    run "ffmpeg -v error -i #{se @item.full_path} -vsync 1 -vf fps=#{FPS} -y #{se tmp_embedding}/embed%06d.bmp"
    
    detection_files = Dir.glob("#{tmp_detection}/*.bmp").sort
    embedding_files = Dir.glob("#{tmp_embedding}/*.bmp").sort
    
    # Create a lookup for embedding frames
    embedding_frame_lookup = {}
    embedding_files.each_with_index do |path, index|
      timestamp = (index + 0.5) / FPS
      embedding_frame_lookup[timestamp] = path
    end
    
    # Process all frames for face detection
    all_frame_faces = []
    detection_files.each_with_index do |path, index|
      timestamp = (index + 0.5) / DETECTION_FPS
      frame_faces = detect_faces_in_frame(path, timestamp)
      all_frame_faces << { timestamp: timestamp, faces: frame_faces }
    end
    
    # Group faces into trails
    face_trails = create_face_trails(all_frame_faces)
    
    # Process embedding frames and assign to trails
    embedding_files.each_with_index do |path, index|
      timestamp = (index + 0.5) / FPS
      process_embedding_frame(path, timestamp, face_trails)
    end
    
    # Save trails and update representative faces
    face_trails.each do |trail|
      trail.update_representative_face!
    end
    
    FileUtils.rm_rf tmp_detection
    FileUtils.rm_rf tmp_embedding
  end
  
  def detect_faces_in_frame(path, timestamp)
    res = post_image 'http://face:5000/detect', path
    faces = []
    
    res.each do |k, info|
      region = info[:facial_area]
      center_x = (region[0] + region[2]) / 2.0
      center_y = (region[1] + region[3]) / 2.0
      width = region[2] - region[0]
      height = region[3] - region[1]
      
      faces << {
        timestamp: timestamp,
        center_x: center_x,
        center_y: center_y,
        width: width,
        height: height,
        position: info.to_json
      }
    end
    
    faces
  end
  
  def create_face_trails(all_frame_faces)
    trails = []
    
    all_frame_faces.each do |frame_data|
      timestamp = frame_data[:timestamp]
      faces = frame_data[:faces]
      
      faces.each do |face_data|
        # Try to find an existing trail this face belongs to
        matching_trail = find_matching_trail(trails, face_data, timestamp)
        
        if matching_trail
          # Add face to existing trail
          face = create_face_for_trail(face_data, matching_trail, true)
          update_trail_bounds(matching_trail, face_data, timestamp)
        else
          # Create new trail
          trail = FaceTrail.create!(
            item: @item,
            start_timestamp: timestamp,
            end_timestamp: timestamp,
            center_x: face_data[:center_x],
            center_y: face_data[:center_y],
            width: face_data[:width],
            height: face_data[:height]
          )
          trails << trail
          create_face_for_trail(face_data, trail, true)
        end
      end
    end
    
    trails
  end
  
  def find_matching_trail(trails, face_data, timestamp)
    trails.find do |trail|
      # Check if this face is close enough in position and time to belong to this trail
      distance = Math.sqrt(
        (trail.center_x - face_data[:center_x])**2 + 
        (trail.center_y - face_data[:center_y])**2
      )
      
      time_gap = timestamp - trail.end_timestamp
      
      distance < TRAIL_DISTANCE_THRESHOLD && 
      time_gap < TRAIL_TIME_THRESHOLD && 
      time_gap >= 0
    end
  end
  
  def create_face_for_trail(face_data, trail, frame_only = false)
    face = Face.create!(
      item: @item,
      face_trail: trail,
      position: face_data[:position],
      timestamp: face_data[:timestamp],
      frame_only: frame_only
    )
    
    if frame_only
      @item.face_count += 1
    end
    
    face
  end
  
  def update_trail_bounds(trail, face_data, timestamp)
    trail.end_timestamp = timestamp
    # Update center position as a weighted average
    trail.center_x = (trail.center_x + face_data[:center_x]) / 2.0
    trail.center_y = (trail.center_y + face_data[:center_y]) / 2.0
    trail.width = (trail.width + face_data[:width]) / 2.0
    trail.height = (trail.height + face_data[:height]) / 2.0
    trail.save!
  end
  
  def process_embedding_frame(path, timestamp, face_trails)
    res = post_image 'http://face:5000/detect', path
    
    res.each do |k, info|
      region = info[:facial_area]
      center_x = (region[0] + region[2]) / 2.0
      center_y = (region[1] + region[3]) / 2.0
      
      # Find the closest trail by position and time
      closest_trail = face_trails.min_by do |trail|
        position_distance = Math.sqrt(
          (trail.center_x - center_x)**2 + 
          (trail.center_y - center_y)**2
        )
        time_distance = (trail.middle_timestamp - timestamp).abs
        position_distance + time_distance * 10  # Weight time more heavily
      end
      
      if closest_trail
        face = Face.create!(
          item: @item,
          face_trail: closest_trail,
          position: info.to_json,
          timestamp: timestamp,
          frame_only: false
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
        face.save!

        @item.face_count += 1
      end
    end
  end
end
