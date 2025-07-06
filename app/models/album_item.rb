class AlbumItem < ActiveRecord::Base
  belongs_to :album
  belongs_to :item
  belongs_to :added_by, class_name: 'User'
  
  validates :album_id, uniqueness: { scope: :item_id }
end