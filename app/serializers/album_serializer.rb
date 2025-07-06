class AlbumSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :created_at, :updated_at, :last_updated_at, :item_count
  
  belongs_to :user, serializer: UserSerializer
  has_many :items, serializer: ItemSerializer
  
  def item_count
    object.album_items.count
  end
  
  def last_updated_at
    object.last_updated_at
  end
end