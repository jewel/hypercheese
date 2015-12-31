class ItemSerializer < ActiveModel::Serializer
  attributes :id, :has_comments, :variety, :starred
  has_many :tags

  def has_comments
    object.comments.any?
  end

  def starred
    object.starred_by.member? scope
  end
end
