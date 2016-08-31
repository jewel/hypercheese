class BullhornSerializer < ActiveModel::Serializer
  attributes :id, :created_at, :item_id
  has_one :user, include: true
end
