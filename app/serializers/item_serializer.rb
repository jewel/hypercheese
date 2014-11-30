class ItemSerializer < ActiveModel::Serializer
  attributes :id, :taken, :width, :height, :tags
end
