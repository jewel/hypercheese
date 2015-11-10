class CommentSerializer < ActiveModel::Serializer
  attributes :id, :text, :created_at, :item_id
  has_one :user, include: true

  def created_at
    object.created_at.strftime('%e %b %Y %H:%M%p')
  end
end
