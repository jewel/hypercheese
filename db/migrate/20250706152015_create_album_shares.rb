class CreateAlbumShares < ActiveRecord::Migration
  def change
    create_table :album_shares do |t|
      t.references :album, index: true, null: false
      t.string :code, null: false
      t.boolean :allows_uploads, default: false, null: false
      t.timestamps null: false
    end
    
    add_index :album_shares, :code, unique: true
  end
end