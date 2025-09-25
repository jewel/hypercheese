require 'exifr/jpeg'
require_dependency 'probe'

class Item < ActiveRecord::Base
  has_many :item_tags
  has_many :tags, through: :item_tags
  has_many :item_locations
  has_many :locations, through: :item_locations
  has_many :item_places
  has_many :places, through: :item_places
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

  scope :can_be_shown_everywhere, -> {
    items = self

    delete_tag = Tag.where( label: 'delete' ).first
    if delete_tag
      items = items.where [ 'id not in ( select item_id from item_tags where tag_id = ?)', delete_tag.id ]
    end

    hidden_tag = Tag.where( label: 'Hidden' ).first
    if hidden_tag
      items = items.where [ 'id not in ( select item_id from item_tags where tag_id = ?)', hidden_tag.id ]
    end

    items = items.where(published: true, deleted: false)
  }

  scope :visible_to, ->(user) {
    if user
      where(
        "published = 1 OR id IN (SELECT item_id FROM item_paths WHERE source_id IN (select id from sources where user_id = ?))",
        user.id
      )
    else
      where(published: true)
    end
  }

  # Check visibility on one item
  #
  # Use the visible_to scope instead for larger batches of items
  def check_visibility_for user
    return if published
    raise "Must be logged in to see this item" unless user
    sources.each do |source|
      next unless source.user_id
      return if source.user_id == user.id
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
    EXIFR::JPEG.new full_path
  rescue
    nil
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
    # The priority should be:
    # 1st: images
    # 2nd: videos
    # 3rd: AI features for images
    # 4th: AI features for videos
    #
    # The reason we want priorities at all is sometimes large batches of videos
    # cor photos come in and they push everyone else's imports back for hours.
    # By prioritizing each step, we can have the most important stuff happen
    # first.
    p = priority_offset
    p += 10 if video?

    LoadMetadataJob.set(priority: 0 + p).perform_later id
    GenerateThumbsJob.set(priority: 1 + p).perform_later id
    if video?
      GenerateExplodedVideoJob.set(priority: 2 + p).perform_later id
      GenerateVideoStreamJob.set(priority: 3 + p).perform_later id
    end
    GeolocateJob.set(priority: 4 + p).perform_later id
    FindFacesJob.set(priority: 25 + p).perform_later id
    IndexVisuallyJob.set(priority: 26 + p).perform_later id
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

    # Fetch in batches because occasionally a deleted or unpublished item will
    # be in the top results.
    visible_items = []
    ids.each_slice(20) do |batch_ids|
      batch_items = Item.includes(:comments, :tags, :stars, :bullhorns, :ratings).can_be_shown_everywhere.where(id: batch_ids)
      visible_items.concat batch_items.to_a
      break if visible_items.length >= 20
    end

    visible_items.first 20
  end

  # Assign places based on GPS coordinates
  def assign_places!
    return if latitude.nil? || longitude.nil?

    containing_places = Place.containing_coordinate latitude, longitude

    containing_places.each do |place|
      unless item_places.exists? place_id: place.id
        item_places.create! place_id: place.id
      end
    end
  end
end

