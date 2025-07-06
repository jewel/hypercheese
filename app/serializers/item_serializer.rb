class ItemSerializer < ActiveModel::Serializer
  attributes :id, :code, :has_comments, :variety, :starred, :bullhorned, :rating, :tag_ids, :has_motion_video, :motion_video_url

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
      # Rating should already be loaded from database using "includes", so
      # don't use a "where" here or rails will run another query

      rating = object.ratings.to_a.select{ |rating| rating.user_id == scope.id }.first
      rating.value if rating
    end
  end

  def has_motion_video
    object.has_motion_video?
  end

  def motion_video_url
    object.motion_video_url
  end
end
