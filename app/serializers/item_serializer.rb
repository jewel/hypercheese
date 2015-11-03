class ItemSerializer < ActiveModel::Serializer
  attributes :id, :has_comments, :variety
  has_many :tags

  def has_comments
    object.comments.any?
  end
end
