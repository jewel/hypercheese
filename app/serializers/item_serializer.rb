class ItemSerializer < ActiveModel::Serializer
  embed :ids
  attributes :id, :taken, :width, :height, :has_comments, :variety
  has_many :tags

  def has_comments
    object.comments.any?
  end
end
