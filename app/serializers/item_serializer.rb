class ItemSerializer < ActiveModel::Serializer
  attributes :id, :taken, :width, :height
  has_many :tags
  embed :ids
end
