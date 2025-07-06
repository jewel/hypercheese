class FaceTrail < ActiveRecord::Base
  belongs_to :item
  belongs_to :representative_face, class_name: 'Face', optional: true
  has_many :faces, dependent: :destroy

  # Calculate the middle timestamp of the trail
  def middle_timestamp
    (start_timestamp + end_timestamp) / 2
  end

  # Get all unique tag names for faces in this trail
  def tag_names
    names = []
    faces.includes(:tag, :cluster).each do |face|
      if face.tag
        names << face.tag.label
      elsif face.cluster&.tag
        names << face.cluster.tag.label
      end
    end
    names.uniq.compact
  end

  # Get the most common tag name for this trail
  def primary_tag_name
    tag_counts = Hash.new(0)
    faces.includes(:tag, :cluster).each do |face|
      if face.tag
        tag_counts[face.tag.label] += 1
      elsif face.cluster&.tag
        tag_counts[face.cluster.tag.label] += 1
      end
    end
    tag_counts.max_by { |_name, count| count }&.first
  end

  # Get faces that have embeddings (every 2 seconds)
  def faces_with_embeddings
    faces.where(frame_only: false)
  end

  # Get all frame positions for this trail
  def frame_positions
    faces.order(:timestamp).map do |face|
      position = JSON.parse(face.position)
      {
        timestamp: face.timestamp,
        x: position.dig('facial_area', 0) || 0,
        y: position.dig('facial_area', 1) || 0,
        width: (position.dig('facial_area', 2) || 0) - (position.dig('facial_area', 0) || 0),
        height: (position.dig('facial_area', 3) || 0) - (position.dig('facial_area', 1) || 0)
      }
    end
  end

  # Update the representative face to be the one closest to the middle timestamp
  def update_representative_face!
    middle_ts = middle_timestamp
    closest_face = faces_with_embeddings.min_by { |f| (f.timestamp - middle_ts).abs }
    if closest_face
      self.representative_face = closest_face
      save!
    end
  end
end