class CommentSerializer < ActiveModel::Serializer
  attributes :id, :text, :created_at, :item_id, :username

  def username
    object.user.name
  end
end
