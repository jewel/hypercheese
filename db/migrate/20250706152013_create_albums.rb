class CreateAlbums < ActiveRecord::Migration
  def change
    create_table :albums do |t|
      t.string :name, null: false
      t.text :description
      t.references :user, index: true, null: false
      t.timestamps null: false
    end
  end
end