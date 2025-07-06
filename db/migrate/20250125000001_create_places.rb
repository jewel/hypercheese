class CreatePlaces < ActiveRecord::Migration[7.2]
  def change
    create_table :places do |t|
      t.string :name, null: false
      t.decimal :latitude, precision: 10, scale: 6, null: false
      t.decimal :longitude, precision: 10, scale: 6, null: false
      t.decimal :radius, precision: 8, scale: 2, null: false
      t.bigint :created_by, null: false
      t.timestamps
    end

    add_index :places, :name
    add_index :places, [:latitude, :longitude]
    add_index :places, :created_by
  end
end