class AddLocations < ActiveRecord::Migration[6.0]
  def change
    # drop_table :locations
    create_table :locations do |t|
      t.string :name, null: false
      t.string :geoid, null: false
      t.json :properties, null: false
      t.index :name
      t.index :geoid
    end

    create_table :item_locations do |t|
      t.references :item, null: false
      t.references :location, null: false
    end

    change_table :items do |t|
      t.float :latitude
      t.float :longitude
    end
  end
end
