class Item < ActiveRecord::Base
  has_many :item_tags
  has_many :tags, through: :item_tags
  has_many :comments
  has_many :item_paths
  has_many :stars
  has_many :starred_by, through: :stars, source: :user
  belongs_to :group
  belongs_to :event

  BASE_PATH = File.join Rails.root, "originals"
  def full_path
    item_paths.first.try(:full_path)
  end

  def paths
    item_paths
  end

  def path
    item_paths.first.try(:path)
  end

  def source
    return nil unless path
    start_of_path = path.split("/").first
    Source.where(path: start_of_path).first
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

  def camera
    begin
      exif = EXIFR::JPEG.new full_path
      exif.model
    rescue
      nil
    end
  end
end
