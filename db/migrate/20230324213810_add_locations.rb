class AddLocations < ActiveRecord::Migration[6.0]
  def up
    # `locations` already exists at this point: the 2012 initial_tables
    # migration created it as a lookup for events (name + timestamps). This
    # migration reuses the name for geocoded places, which is a different
    # table entirely, so the old one has to go first. Without this, a
    # from-scratch `bin/rails db:migrate` fails here with
    # "Mysql2::Error: Table 'locations' already exists".
    drop_table :locations, if_exists: true

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

  def down
    change_table :items do |t|
      t.remove :latitude, :longitude
    end
    drop_table :item_locations
    drop_table :locations

    # Restore the events lookup table as initial_tables left it.
    create_table :locations do |t|
      t.string :name
      t.timestamps
    end
  end
end
