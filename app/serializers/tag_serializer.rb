class TagSerializer < ActiveModel::Serializer
  attributes :id, :label, :icon, :item_count, :parent_id

  def icon
    object.icon_item_id
  end

  def parent_id
    if object.parent
      object.parent.id
    else
      nil
    end
  end
end
