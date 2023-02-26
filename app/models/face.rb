class Face < ActiveRecord::Base
  belongs_to :item
  belongs_to :tag

  def path
    "#{Rails.root}/public/data/faces/#{item.id}-#{id}-#{item.code}.jpg"
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
