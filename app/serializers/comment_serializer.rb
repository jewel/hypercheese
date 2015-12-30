class CommentSerializer < ActiveModel::Serializer
  attributes :id, :text, :created_at, :item_id
  has_one :user, include: true
end
