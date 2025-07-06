class CreateItemPlaces < ActiveRecord::Migration[7.2]
  def change
    create_table :item_places do |t|
      t.bigint :item_id, null: false
      t.bigint :place_id, null: false
      t.bigint :user_id, null: true  # null if system added
      t.datetime :created_at, null: false
    end

    add_index :item_places, :item_id
    add_index :item_places, :place_id
    add_index :item_places, :user_id
    add_index :item_places, [:item_id, :place_id], unique: true
    add_foreign_key :item_places, :items
    add_foreign_key :item_places, :places
    add_foreign_key :item_places, :users
  end
end