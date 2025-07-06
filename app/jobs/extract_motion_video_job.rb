class ExtractMotionVideoJob < ApplicationJob
  def perform(item_id)
    item = Item.find(item_id)
    return if item.deleted
    return unless item.photo?
    return if item.has_motion_video? # Already extracted
    
    source_path = item.full_path
    return unless source_path && File.exist?(source_path)
    
    # Check if this is a motion photo
    return unless MotionPhotoExtractor.motion_photo?(source_path)
    
    # Set up output directory
    motion_videos_dir = File.join(Rails.root, "public", "data", "motion_videos")
    FileUtils.mkdir_p(motion_videos_dir)
    
    # Generate unique filename for the motion video
    motion_filename = "#{item.id}-#{item.code}.mp4"
    output_path = File.join(motion_videos_dir, motion_filename)
    
    # Extract the motion video
    extracted_path = MotionPhotoExtractor.extract_video(source_path, output_path)
    
    if extracted_path && File.exist?(extracted_path)
      # Update the item with the motion video path
      item.update!(motion_video_path: motion_filename)
      Rails.logger.info "Extracted motion video for item #{item.id}: #{motion_filename}"
    else
      Rails.logger.warn "Failed to extract motion video for item #{item.id}"
    end
  rescue => e
    Rails.logger.error "Error in ExtractMotionVideoJob for item #{item_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end