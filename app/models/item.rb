require 'exifr/jpeg'
require_dependency 'probe'

class Item < ActiveRecord::Base
  has_many :item_tags
  has_many :tags, through: :item_tags
  has_many :item_locations
  has_many :locations, through: :item_locations
  has_many :comments
  has_many :item_paths
  has_many :stars
  has_many :starred_by, through: :stars, source: :user
  has_many :bullhorns
  has_many :bullhorned_by, through: :bullhorns, source: :user
  has_many :ratings
  has_many :sources, through: :item_paths
  has_many :faces
  has_many :clip_frames
  belongs_to :group
  belongs_to :event

  BASE_PATH = File.join Rails.root, "originals"
  def self.published
    where published: true
  end

  # Search items by EXIF data
  def self.search_by_exif(field, value)
    where("JSON_EXTRACT(exif_data, ?) LIKE ?", "$.#{field}", "%#{value}%")
  end

  # Search items by multiple EXIF fields
  def self.search_by_exif_fields(conditions)
    query = self
    conditions.each do |field, value|
      query = query.where("JSON_EXTRACT(exif_data, ?) LIKE ?", "$.#{field}", "%#{value}%")
    end
    query
  end

  # Check visibility on small groups of items
  #
  # The main search results shouldn't use this, it's inefficient.
  def self.check_visibility_for user
    where(published: [nil, false]).includes(:item_paths, :sources).each do |item|
      item.check_visibility_for user
    end
  end

  def check_visibility_for user
    return if published
    raise "Must be logged in to see this item" unless user
    sources.each do |source|
      next unless source.user_id
      return if source.user_id = user.id
    end
    raise "Item #{id} is not published"
  end

  def full_path
    item_paths.first.try(:full_path)
  end

  def paths
    item_paths
  end

  def path
    item_paths.first.try(:path)
  end

  def source_id
    item_paths.first.try(:source_id)
  end

  def resized_path size
    "#{Rails.root}/public/data/resized/#{size}/#{id}-#{code}.jpg"
  end

  def video_stream_path
    "#{Rails.root}/public/data/resized/stream/#{id}-#{code}.mp4"
  end

  def resized_url size
    "/data/resized/#{size}/#{id}-#{code}.jpg"
  end

  def video_stream_url
    "/data/resized/stream/#{id}-#{code}.mp4"
  end

  def tag_ids_as_hash
    hash = {}
    tags.each do |t|
      hash[t.id] = true
    end
    hash
  end

  def exif
    # Return parsed EXIF data from database if available
    return parsed_exif_data if exif_data.present?
    
    # Fallback to reading from file if no database data
    EXIFR::JPEG.new full_path
  rescue
    nil
  end

  def parsed_exif_data
    @parsed_exif_data ||= begin
      return nil unless exif_data.present?
      
      data = JSON.parse(exif_data)
      
      # Create a simple object that behaves like EXIFR::JPEG for backward compatibility
      exif_object = OpenStruct.new
      
      data.each do |key, value|
        # Convert date strings back to DateTime objects if they look like dates
        if key.include?('date') || key.include?('time') 
          begin
            if value.is_a?(String) && value.match?(/^\d{4}[:-]\d{2}[:-]\d{2}/)
              value = DateTime.parse(value)
            end
          rescue
            # Keep as string if parsing fails
          end
        end
        
        exif_object[key] = value
        
        # Also make it accessible as a method for backward compatibility
        exif_object.define_singleton_method(key.to_sym) { value } unless exif_object.respond_to?(key.to_sym)
      end
      
      exif_object
    rescue JSON::ParserError
      nil
    end
  end

  # Get specific EXIF field value
  def exif_field(field)
    return nil unless exif_data.present?
    
    begin
      data = JSON.parse(exif_data)
      data[field.to_s]
    rescue JSON::ParserError
      nil
    end
  end

  def probe
    Probe.video full_path if variety == 'video'
  rescue
    nil
  end

  def photo?
    variety == 'photo'
  end

  def video?
    variety == 'video'
  end

  def schedule_jobs priority_offset=0
    # Deprioritize video since everything takes longer with video
    p = priority_offset
    p += 10 if video?

    LoadMetadataJob.set(priority: 0 + p).perform_later id
    GenerateThumbsJob.set(priority: 1 + p).perform_later id
    if video?
      GenerateExplodedVideoJob.set(priority: 2 + p).perform_later id
      GenerateVideoStreamJob.set(priority: 3 + p).perform_later id
    end
    GeolocateJob.set(priority: 4 + p).perform_later id
    FindFacesJob.set(priority: 5 + p).perform_later id
    IndexVisuallyJob.set(priority: 6 + p).perform_later id
  end

  def similar_items
    store = EmbeddingStore.new "clip", 768
    video_store = EmbeddingStore.new "video-clip", 768
    if photo?
      raw = store.get id
      return nil unless raw
    else
      # We'll average the embeddings of all the frames here since that's going
      # to be better than doing a separate search for each of them.  Who knows
      # what that will do for longer videos but at least we'll get some sort of
      # result.
      embeddings = clip_frames.map do |frame|
        raw = video_store.get frame.id
        return nil unless raw
        raw.unpack 'f*'
      end
      return nil if embeddings.empty?
      average = embeddings.transpose.map do |elements|
        elements.sum / elements.size
      end
      raw = average.pack 'f*'
    end

    # Search photos
    output = store.bulk_cosine_distance raw, 0.8

    # Add in videos
    frames = video_store.bulk_cosine_distance raw, 0.8
    frame_ids = frames.map { _1.last }
    frame_scores = {}
    frames.each do |score, frame_id|
      frame_scores[frame_id] = score
    end
    item_scores = {}
    frame_ids = ClipFrame.where(id: frame_ids).pluck(:id, :item_id).each do |frame_id, item_id|
      score = frame_scores[frame_id]
      item_scores[item_id] ||= []
      item_scores[item_id] << score
    end

    item_scores.each do |item_id, scores|
      output.push [scores.max, item_id]
    end

    output.sort_by! { -_1.first }
    ids = output.map { _1.last }
    ids = ids - [id]
    Item.includes(:comments, :tags, :stars, :bullhorns, :ratings).find ids.first(20)
  end
end

