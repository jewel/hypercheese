# == Schema Information
#
# Table name: items
#
#  id          :integer          not null, primary key
#  taken       :datetime
#  description :text
#  type        :string(255)
#  path        :string(255)
#  md5         :string(255)
#  width       :integer
#  height      :integer
#  view_count  :integer
#  event_id    :integer
#  group_id    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  deleted_at  :datetime
#

class Item < ActiveRecord::Base
  has_many :item_tags
  has_many :tags, through: :item_tags
  has_many :comments
  belongs_to :group
  belongs_to :event

  BASE_PATH = File.join Rails.root, "originals"
  def full_path
    "#{BASE_PATH}/#{path}"
  end

  def resized_path size
    "#{Rails.root}/public/data/resized/#{size}/#{id}.jpg"
  end

  def video_stream_path type
    "#{Rails.root}/public/data/resized/stream/#{id}.#{type}"
  end

  def video_stream_url type
    "/resized/stream/#{id}.#{type}"
  end

  def resized_url size
    "/resized/#{size}/#{id}.jpg"
  end

  def tag_ids_as_hash
    hash = {}
    tags.each do |t|
      hash[t.id] = true
    end
    hash
  end

  def source
    path.split("/").first
  end
end
