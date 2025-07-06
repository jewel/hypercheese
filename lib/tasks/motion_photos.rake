namespace :motion_photos do
  desc "Extract motion videos from existing motion photos"
  task extract: :environment do
    puts "Scanning for motion photos to extract videos..."
    
    motion_videos_dir = File.join(Rails.root, "public", "data", "motion_videos")
    FileUtils.mkdir_p(motion_videos_dir)
    
    processed = 0
    extracted = 0
    errors = 0
    
    Item.where(variety: 'photo').where(motion_video_path: nil).find_each do |item|
      begin
        source_path = item.full_path
        next unless source_path && File.exist?(source_path)
        
        processed += 1
        puts "Processing #{processed}: #{item.path}" if processed % 100 == 0
        
        # Check if this is a motion photo
        next unless MotionPhotoExtractor.motion_photo?(source_path)
        
        # Generate filename for the motion video
        motion_filename = "#{item.id}-#{item.code}.mp4"
        output_path = File.join(motion_videos_dir, motion_filename)
        
        # Extract the motion video
        extracted_path = MotionPhotoExtractor.extract_video(source_path, output_path)
        
        if extracted_path && File.exist?(extracted_path)
          item.update!(motion_video_path: motion_filename)
          extracted += 1
          puts "✓ Extracted motion video for item #{item.id}: #{motion_filename}"
        end
        
      rescue => e
        errors += 1
        puts "✗ Error processing item #{item.id}: #{e.message}"
      end
    end
    
    puts "\nMotion photo extraction complete!"
    puts "Processed: #{processed} photos"
    puts "Extracted: #{extracted} motion videos"
    puts "Errors: #{errors}"
  end
  
  desc "List motion photos in the system"
  task list: :environment do
    puts "Motion photos in the system:"
    
    Item.where(variety: 'photo').find_each do |item|
      source_path = item.full_path
      next unless source_path && File.exist?(source_path)
      
      if MotionPhotoExtractor.motion_photo?(source_path)
        status = item.has_motion_video? ? "✓ extracted" : "✗ not extracted"
        puts "#{item.id}: #{item.path} (#{status})"
      end
    end
  end
  
  desc "Clean up motion videos for deleted items"
  task cleanup: :environment do
    puts "Cleaning up motion videos for deleted items..."
    
    motion_videos_dir = File.join(Rails.root, "public", "data", "motion_videos")
    return unless Dir.exist?(motion_videos_dir)
    
    cleaned = 0
    
    Dir.glob(File.join(motion_videos_dir, "*.mp4")).each do |video_file|
      filename = File.basename(video_file)
      
      # Extract item ID from filename pattern: "123-abcd1234.mp4"
      if filename =~ /^(\d+)-.*\.mp4$/
        item_id = $1.to_i
        item = Item.find_by(id: item_id)
        
        if !item || item.deleted || !item.has_motion_video?
          File.delete(video_file)
          cleaned += 1
          puts "Deleted: #{filename}"
        end
      end
    end
    
    puts "Cleaned up #{cleaned} orphaned motion videos"
  end
end