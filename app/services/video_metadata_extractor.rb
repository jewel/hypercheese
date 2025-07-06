require 'open3'
require 'json'

class VideoMetadataExtractor
  attr_reader :item

  def initialize(item)
    @item = item
    raise ArgumentError, "Item must be a video" unless item.video?
  end

  # Extract all metadata from the video file
  def extract_metadata
    {
      basic_info: extract_basic_info,
      xmp_metadata: extract_xmp_metadata,
      motion_photo_data: extract_motion_photo_data,
      is_pixel_slow_motion: detect_pixel_slow_motion?,
      speed_segments: extract_speed_segments
    }
  end

  # Extract and create speed segments from metadata
  def extract_and_create_speed_segments!
    return unless item.video?

    # Clear existing segments
    item.video_speed_segments.destroy_all

    segments = extract_speed_segments
    
    segments.each do |segment_data|
      item.video_speed_segments.create!(
        start_time: segment_data[:start_time],
        end_time: segment_data[:end_time],
        playback_rate: segment_data[:playback_rate],
        source_type: segment_data[:source_type],
        metadata: segment_data[:metadata].to_json
      )
    end

    segments.any?
  end

  private

  def extract_basic_info
    probe_data = run_ffprobe_json
    return {} unless probe_data

    video_stream = probe_data['streams']&.find { |s| s['codec_type'] == 'video' }
    return {} unless video_stream

    {
      duration: probe_data.dig('format', 'duration')&.to_f,
      width: video_stream['width'],
      height: video_stream['height'],
      frame_rate: eval_frame_rate(video_stream['r_frame_rate']),
      codec: video_stream['codec_name'],
      creation_time: probe_data.dig('format', 'tags', 'creation_time')
    }
  end

  def extract_xmp_metadata
    # Try to extract XMP metadata using ffprobe
    cmd = [
      'ffprobe',
      '-v', 'error',
      '-show_entries', 'format_tags',
      '-of', 'json',
      item.full_path
    ]

    stdout, stderr, status = Open3.capture3(*cmd)
    return {} unless status.success?

    begin
      data = JSON.parse(stdout)
      tags = data.dig('format', 'tags') || {}
      
      # Look for XMP or motion photo related tags
      xmp_tags = tags.select { |k, v| k.downcase.include?('xmp') || k.downcase.include?('motion') }
      
      {
        all_tags: tags,
        xmp_tags: xmp_tags,
        camera_make: tags['make'] || tags['com.android.manufacturer'],
        camera_model: tags['model'] || tags['com.android.model'],
        motion_photo: tags['Camera:MotionPhoto'],
        motion_photo_timestamp: tags['Camera:MotionPhotoPresentationTimestampUs']
      }
    rescue JSON::ParserError
      {}
    end
  end

  def extract_motion_photo_data
    # Try to extract Motion Photo specific metadata
    # This would need to be expanded based on actual Pixel video format specifications
    
    xmp_data = extract_xmp_metadata
    
    return {} unless xmp_data[:motion_photo] == '1'

    {
      is_motion_photo: true,
      presentation_timestamp: xmp_data[:motion_photo_timestamp]&.to_i,
      camera_make: xmp_data[:camera_make],
      camera_model: xmp_data[:camera_model]
    }
  end

  def detect_pixel_slow_motion?
    xmp_data = extract_xmp_metadata
    
    # Check for Pixel phone indicators
    is_pixel = xmp_data[:camera_make]&.downcase&.include?('google') ||
               xmp_data[:camera_model]&.downcase&.include?('pixel')
    
    # Check for motion photo or slow motion indicators
    has_motion_data = xmp_data[:motion_photo] == '1' ||
                      xmp_data[:all_tags].any? { |k, v| k.downcase.include?('slow') }

    is_pixel && has_motion_data
  end

  def extract_speed_segments
    # Try multiple methods to extract speed segments
    segments = []
    
    # Method 1: From XMP metadata (if available)
    segments.concat(extract_from_xmp_metadata)
    
    # Method 2: From video metadata tracks (if available)
    segments.concat(extract_from_metadata_tracks)
    
    # Method 3: Fallback - create segments based on video characteristics
    segments = create_fallback_segments if segments.empty?

    segments
  end

  def extract_from_xmp_metadata
    # This would need to be implemented based on the actual
    # Pixel slow motion metadata format when discovered
    []
  end

  def extract_from_metadata_tracks
    # Try to extract from metadata tracks in the video
    cmd = [
      'ffprobe',
      '-v', 'error',
      '-select_streams', 'm',
      '-show_entries', 'stream_tags',
      '-of', 'json',
      item.full_path
    ]

    stdout, stderr, status = Open3.capture3(*cmd)
    return [] unless status.success?

    begin
      data = JSON.parse(stdout)
      # Process metadata streams here
      # This would need actual implementation based on Pixel format
      []
    rescue JSON::ParserError
      []
    end
  end

  def create_fallback_segments
    # Create basic segments if no metadata is found
    # This provides a foundation for manual editing
    
    basic_info = extract_basic_info
    duration = basic_info[:duration]
    return [] unless duration && duration > 0

    if detect_pixel_slow_motion?
      # Create segments that might represent typical slow motion patterns
      [
        {
          start_time: 0.0,
          end_time: duration * 0.3,
          playback_rate: 1.0,
          source_type: 'fallback',
          metadata: { note: 'Normal speed - estimated' }
        },
        {
          start_time: duration * 0.3,
          end_time: duration * 0.7,
          playback_rate: 0.25,
          source_type: 'fallback',
          metadata: { note: 'Slow motion - estimated' }
        },
        {
          start_time: duration * 0.7,
          end_time: duration,
          playback_rate: 1.0,
          source_type: 'fallback',
          metadata: { note: 'Normal speed - estimated' }
        }
      ]
    else
      # Single normal speed segment for non-slow-motion videos
      [
        {
          start_time: 0.0,
          end_time: duration,
          playback_rate: 1.0,
          source_type: 'fallback',
          metadata: { note: 'Normal speed - default' }
        }
      ]
    end
  end

  def run_ffprobe_json
    cmd = [
      'ffprobe',
      '-v', 'error',
      '-show_format',
      '-show_streams',
      '-of', 'json',
      item.full_path
    ]

    stdout, stderr, status = Open3.capture3(*cmd)
    return nil unless status.success?

    begin
      JSON.parse(stdout)
    rescue JSON::ParserError
      nil
    end
  end

  def eval_frame_rate(rate_string)
    return nil unless rate_string
    
    if rate_string.include?('/')
      numerator, denominator = rate_string.split('/').map(&:to_f)
      return nil if denominator.zero?
      numerator / denominator
    else
      rate_string.to_f
    end
  end
end