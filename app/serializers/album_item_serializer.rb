class AlbumItemSerializer < ActiveModel::Serializer
  attributes :id, :created_at
  
  belongs_to :album, serializer: AlbumSerializer
  belongs_to :item, serializer: ItemSerializer
  belongs_to :added_by, serializer: UserSerializer
end