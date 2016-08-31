class ItemSerializer < ActiveModel::Serializer
  attributes :id, :has_comments, :variety, :starred, :bullhorned, :rating
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

  def bullhorned
    if scope
      object.bullhorns.select { |_| _.user_id == scope.id }.any?
    else
      false
    end
  end

  def rating
    if scope
      rating = object.ratings.where(user_id: scope.id).first
      rating.value if rating
    end
  end
end
