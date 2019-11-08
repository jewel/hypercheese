require 'exifr/jpeg'

class Item < ActiveRecord::Base
  has_many :item_tags
  has_many :tags, through: :item_tags
  has_many :comments
  has_many :item_paths
  has_many :stars
  has_many :starred_by, through: :stars, source: :user
  has_many :bullhorns
  has_many :bullhorned_by, through: :bullhorns, source: :user
  has_many :ratings
  has_many :sources, through: :item_paths
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
    "#{Rails.root}/public/data/resized/#{size}/#{id}.jpg"
  end

  def video_stream_path
    "#{Rails.root}/public/data/resized/stream/#{id}.mp4"
  end

  def video_stream_url
    "/data/resized/stream/#{id}.mp4"
  end

  def resized_url size
    "/data/resized/#{size}/#{id}.jpg"
  end

  def tag_ids_as_hash
    hash = {}
    tags.each do |t|
      hash[t.id] = true
    end
    hash
  end

  def exif
    begin
      EXIFR::JPEG.new full_path
    rescue
      nil
    end
  end
end
