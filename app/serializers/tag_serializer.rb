class TagSerializer < ActiveModel::Serializer
  attributes :id, :label, :icon, :item_count

  def icon
    object.icon_item_id
  end
end
