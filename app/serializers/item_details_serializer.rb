class ItemDetailsSerializer < ActiveModel::Serializer
  attributes :id, :taken, :width, :height, :exif, :probe, :paths, :ages, :filesize, :pretty_size, :faces, :aesthetics_score, :locations, :places
  has_many :comments, include: true

  def exif
    object.exif&.as_json&.except "user_comment"
  end

  def comments
    object.comments.order :created_at
  end

  def locations
    object.locations.map &:name
  end

  def places
    object.places.map &:name
  end

  def paths
    object.paths.map &:path_with_source
  end

  include ActionView::Helpers::NumberHelper
  def pretty_size
    number_to_human_size filesize if filesize
  end

  def filesize
    File.size object.full_path rescue nil
  end

  def faces
    object.faces.includes(:cluster).order(:timestamp, :cluster_id).map do |face|
      {
        id: face.id,
        tag_id: face.tag_id,
        cluster_tag_id: face.cluster&.tag_id,
        similarity: face.similarity,
      }
    end
  end

  include ActionView::Helpers::DateHelper
  def ages
    age_map = {}
    tags = object.tags.to_a
    object.faces.includes(:tag, :cluster).each do |face|
      if face.tag_id
        tags << face.tag
      end
      if face.cluster_id && face.cluster.tag_id
        tags << face.cluster.tag
      end
    end
    tags.uniq!

    tags.each do |tag|
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
