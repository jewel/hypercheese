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
  belongs_to :group
  belongs_to :event

  BASE_PATH = File.join Rails.root, "originals"
  def self.published
    where published: true
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
    # Deprioritize video since everything takes longer with video
    p = priority_offset
    p += 10 if video?

    LoadMetadataJob.set(priority: 0 + p).perform_later id
    GenerateThumbsJob.set(priority: 1 + p).perform_later id
    GeolocateJob.set(priority: 2 + p).perform_later id
    FindFacesJob.set(priority: 3 + p).perform_later id
    IndexVisuallyJob.set(priority: 4 + p).perform_later id

    if video?
      GenerateExplodedVideoJob.set(priority: 5 + p).perform_later id
      GenerateVideoStreamJob.set(priority: 6 + p).perform_later id
    end
  end

  def similar_items
    return nil unless photo?
    store = EmbeddingStore.new "clip", 768
    raw = store.get id
    return nil unless raw
    output = store.bulk_cosine_distance raw, 0.8
    output.sort_by! { -_1.first }
    ids = output.map { _1.last }
    ids.shift if ids.first == id
    Item.includes(:comments, :tags, :stars, :bullhorns, :ratings).find ids.first(20)
  end
end

