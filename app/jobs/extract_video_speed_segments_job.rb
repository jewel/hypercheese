class ExtractVideoSpeedSegmentsJob < ApplicationJob
  queue_as :default

  def perform(item_id)
    item = Item.find(item_id)
    return unless item.video?

    Rails.logger.info "Extracting video speed segments for item #{item_id}"

    begin
      extractor = VideoMetadataExtractor.new(item)
      segments_created = extractor.extract_and_create_speed_segments!
      
      if segments_created
        Rails.logger.info "Created #{item.video_speed_segments.count} speed segments for item #{item_id}"
      else
        Rails.logger.info "No speed segments found for item #{item_id}"
      end
      
    rescue StandardError => e
      Rails.logger.error "Failed to extract speed segments for item #{item_id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end