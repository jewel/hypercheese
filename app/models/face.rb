class Face < ActiveRecord::Base
  belongs_to :item
  belongs_to :tag

  def path
    "#{Rails.root}/public/data/faces/#{item.id}-#{id}-#{item.code}.jpg"
  end

  def embedding_path
    "#{Rails.root}/public/data/faces/#{item.id}-#{id}-#{item.code}.json"
  end
end
