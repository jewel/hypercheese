require_relative '../../lib/embedding_store'
require_relative '../../lib/native_functions'

class Face < ActiveRecord::Base
  belongs_to :item
  belongs_to :tag
  belongs_to :cluster, class_name: 'Face'

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
  end

  def store
    @@_store ||= EmbeddingStore.new "facenet512", 512
  end
end
