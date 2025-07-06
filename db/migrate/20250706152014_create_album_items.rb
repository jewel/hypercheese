class CreateAlbumItems < ActiveRecord::Migration
  def change
    create_table :album_items do |t|
      t.references :album, index: true, null: false
      t.references :item, index: true, null: false
      t.references :added_by, index: true, null: false
      t.timestamps null: false
    end
    
    add_index :album_items, [:album_id, :item_id], unique: true
  end
end