class CommentSerializer < ActiveModel::Serializer
  embed :ids
  attributes :id, :text, :created_at
  has_one :user, include: true

  def created_at
    object.created_at.strftime('%e %b %Y %H:%M%p')
  end
end
