class ItemSerializer < ActiveModel::Serializer
  embed :ids
  attributes :id, :taken, :width, :height
  has_many :tags
  has_many :comments
end
