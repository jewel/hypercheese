class ItemDetailsSerializer < ActiveModel::Serializer
  attributes :id, :taken, :width, :height, :exif, :paths, :ages
  has_many :comments, include: true

  def comments
    object.comments.order :created_at
  end

  def paths
    object.paths.map &:path
  end

  include ActionView::Helpers::DateHelper
  def ages
    age_map = {}
    object.tags.each do |tag|
      next unless tag.birthday
      age = if tag.birthday > object.taken
        distance_of_time_in_words(object.taken, tag.birthday) + " in the PAST!?"
      else
        distance_of_time_in_words(tag.birthday, object.taken) + " old"
      end
      age_map[tag.id] = age
    end
    age_map
  end
end
