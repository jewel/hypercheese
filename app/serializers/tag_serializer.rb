class TagSerializer < ActiveModel::Serializer
  attributes :id, :label, :icon, :item_count, :parent_id, :alias

  def icon
    object.icon_item_id
  end

  def alias
    tag_alias = object.tag_aliases.where(user_id: scope.id).first
    tag_alias && tag_alias.alias || nil
  end

  def parent_id
    if object.parent
      object.parent.id
    else
      nil
    end
  end
end
