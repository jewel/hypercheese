class ItemSerializer < ActiveModel::Serializer
  embed :ids
  attributes :id, :taken, :width, :height, :has_comments, :variety
  has_many :tags
  has_many :comments

  def has_comments
    comments.any?
  end
end
