class CommentSerializer < ActiveModel::Serializer
  attributes :id, :text, :created_at
  has_one :user
  has_one :item
end
