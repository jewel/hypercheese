class PlaceSerializer < ActiveModel::Serializer
  attributes :id, :name, :latitude, :longitude, :radius, :created_at, :updated_at, :creator_name, :item_count

  def creator_name
    object.creator.username
  end

  def item_count
    object.items.count
  end
end