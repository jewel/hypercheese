class TagSerializer < ActiveModel::Serializer
  attributes :id, :label, :icon

  def icon
    object.icon_item_id
  end
end
