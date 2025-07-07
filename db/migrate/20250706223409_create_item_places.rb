class CreateItemPlaces < ActiveRecord::Migration[7.2]
  def change
    create_table :item_places do |t|
      t.integer :item_id, null: false
      t.integer :place_id, null: false
      t.integer :user_id, null: true  # null if system added
      t.datetime :created_at, null: false
    end

    add_index :item_places, :item_id
    add_index :item_places, :place_id
    add_index :item_places, :user_id
    add_index :item_places, [:item_id, :place_id], unique: true
  end
end
