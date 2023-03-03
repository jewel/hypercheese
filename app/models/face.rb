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
    raise "Sizes do not match" unless a.size == b.size
    dot_product = 0
    a.zip(b).each do |a1, b1|
      dot_product += a1 * b1
    end
    at = a.map { |n| n ** 2 }.sum
    bt = b.map { |n| n ** 2 }.sum
    dot_product / (Math.sqrt(at) * Math.sqrt(bt))
  end

  def path
    "#{Rails.root}/public/#{url}"
  end

  def url
    "/data/faces/#{item.id}-#{id}-#{item.code}.jpg"
  end

  def embedding_path
    "#{Rails.root}/public/data/faces/#{item.id}-#{id}-#{item.code}.facenet512.json"
  end

  def embedding?
    @_embedding || File.exist?(embedding_path)
  end

  def embedding
    @_embedding ||= JSON.parse File.binread embedding_path
  end
end
