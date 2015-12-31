class ItemSerializer < ActiveModel::Serializer
  attributes :id, :has_comments, :variety, :starred
  has_many :tags

  def has_comments
    object.comments.any?
  end

  def starred
    if scope
      object.stars.select { |_| _.user_id == scope.id }.any?
    else
      false
    end
  end
end
