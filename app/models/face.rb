require_dependency 'native_functions'

class Face < ActiveRecord::Base
  belongs_to :item
  belongs_to :tag
  belongs_to :cluster, class_name: 'Face'
  belongs_to :face_trail, optional: true

  DISTANCE_THRESHOLD = 0.7

  # cosine distance of two face embeddings, expressed as a floating point number
  # between 0 and 1.  The higher the number, the more similar the two images
  # are.
  def distance other
    a = embedding
    b = other.embedding
    raise "Sizes do not match" unless a.bytesize == b.bytesize

    NativeFunctions.cosine_distance a, b
  end

  def path
    "#{Rails.root}/public/#{url}"
  end

  def url
    "/data/faces/#{item.id}-#{id}-#{item.code}.jpg"
  end

  def embedding?
    @_embedding || store.has(id)
  end

  def embedding
    @_embedding ||= store.get(id)
  end

  def set_embedding data
    @_embedding = nil
    store.put id, data
    join_cluster
  end

  # Find out which cluster this face belongs to
  def join_cluster
    canonical = Face.where.not(tag_id: nil)
    winner = nil
    max = -2.0

    canonical.each do |canon|
      diff = canon.distance self
      if diff > max
        winner = canon
        max = diff
      end
    end

    if winner && max >= DISTANCE_THRESHOLD
      self.cluster_id = winner.id
      self.similarity = max
    end
  end

  # Grab all faces and add them to our cluster
  def build_cluster
    raise "Should be done in a transaction" unless self.class.connection.transaction_open?
    output = store.bulk_cosine_distance embedding, DISTANCE_THRESHOLD
    ids = output.map &:last
    faces_by_id = Face.where(id: ids).where(tag_id: nil).index_by &:id
    output.each do |(distance, id)|
      face = faces_by_id[id]
      next unless face # face must have been deleted
      next if face.cluster_id && face.similarity >= distance
      face.cluster_id = self.id
      face.similarity = distance
      face.save!
    end
    nil
  end

  def destroy_cluster
    raise "Should be done in a transaction" unless self.class.connection.transaction_open?
    Face.where(cluster_id: self.id).each do |face|
      face.cluster_id = nil
      face.similarity = nil
      face.join_cluster
      face.save!
    end
    nil
  end

  def store
    @@_store ||= EmbeddingStore.new "facenet512", 512
  end
end
