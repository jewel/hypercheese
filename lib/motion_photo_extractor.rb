require 'exifr/jpeg'

class MotionPhotoExtractor
  # Detect if a file is a Google Pixel motion photo
  def self.motion_photo?(file_path)
    return false unless File.exist?(file_path)
    return false unless file_path.downcase.end_with?('.jpg', '.jpeg')
    
    # Check filename patterns
    basename = File.basename(file_path)
    return true if basename =~ /^PXL_.*\.MP\.jpg$/i
    return true if basename =~ /^MVIMG_.*\.jpg$/i
    
    # Check EXIF data for motion photo markers
    begin
      exif = EXIFR::JPEG.new(file_path)
      return false unless exif
      
      # Check for motion photo metadata
      if exif.respond_to?(:xmp) && exif.xmp
        xmp_string = exif.xmp.to_s
        return true if xmp_string.include?('MotionPhoto')
        return true if xmp_string.include?('MicroVideo')
      end
    rescue => e
      Rails.logger.warn "Error reading EXIF from #{file_path}: #{e.message}"
    end
    
    false
  end
  
  # Extract the embedded video from a motion photo
  def self.extract_video(motion_photo_path, output_path = nil)
    return nil unless motion_photo?(motion_photo_path)
    
    unless output_path
      base = File.basename(motion_photo_path, '.*')
      dir = File.dirname(motion_photo_path)
      output_path = File.join(dir, "#{base}_motion.mp4")
    end
    
    begin
      # Try XMP metadata extraction first (newer format)
      if extract_using_xmp(motion_photo_path, output_path)
        return output_path
      end
      
      # Fall back to binary search method
      if extract_using_binary_search(motion_photo_path, output_path)
        return output_path
      end
      
    rescue => e
      Rails.logger.error "Error extracting motion video from #{motion_photo_path}: #{e.message}"
      File.delete(output_path) if File.exist?(output_path)
    end
    
    nil
  end
  
  private
  
  # Extract using XMP metadata (preferred method for newer files)
  def self.extract_using_xmp(motion_photo_path, output_path)
    exif = EXIFR::JPEG.new(motion_photo_path)
    return false unless exif&.xmp
    
    xmp_string = exif.xmp.to_s
    
    # Look for Container metadata with video length
    if match = xmp_string.match(/Item:Length="(\d+)".*?Item:Semantic="MotionPhoto"/m)
      video_length = match[1].to_i
      return false if video_length <= 0
      
      file_size = File.size(motion_photo_path)
      video_start = file_size - video_length
      
      File.open(motion_photo_path, 'rb') do |input|
        input.seek(video_start)
        File.open(output_path, 'wb') do |output|
          output.write(input.read(video_length))
        end
      end
      
      return File.exist?(output_path) && File.size(output_path) > 0
    end
    
    # Look for MicroVideoOffset (older format)
    if match = xmp_string.match(/MicroVideoOffset['"]\s*[=:]\s*['"](\d+)['"]/i)
      offset_from_end = match[1].to_i
      return false if offset_from_end <= 0
      
      file_size = File.size(motion_photo_path)
      video_start = file_size - offset_from_end
      
      File.open(motion_photo_path, 'rb') do |input|
        input.seek(video_start)
        File.open(output_path, 'wb') do |output|
          output.write(input.read(offset_from_end))
        end
      end
      
      return File.exist?(output_path) && File.size(output_path) > 0
    end
    
    false
  end
  
  # Extract using binary search for MP4 header (fallback method)
  def self.extract_using_binary_search(motion_photo_path, output_path)
    # Look for MP4 file type headers
    mp4_patterns = [
      "\x00\x00\x00\x18\x66\x74\x79\x70\x6d\x70\x34\x32", # ftypmp42
      "\x00\x00\x00\x1c\x66\x74\x79\x70\x69\x73\x6f\x6d", # ftypisom
      "\x00\x00\x00\x20\x66\x74\x79\x70\x69\x73\x6f\x6d"  # ftypisom (alternative)
    ]
    
    File.open(motion_photo_path, 'rb') do |file|
      content = file.read
      
      mp4_patterns.each do |pattern|
        if pos = content.index(pattern)
          video_data = content[pos..-1]
          next if video_data.length < 1000 # Skip if too small
          
          File.open(output_path, 'wb') do |output|
            output.write(video_data)
          end
          
          return File.exist?(output_path) && File.size(output_path) > 0
        end
      end
    end
    
    false
  end
end