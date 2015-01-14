class TagSerializer < ActiveModel::Serializer
  attributes :id, :label
  embed :ids, include: false
end
