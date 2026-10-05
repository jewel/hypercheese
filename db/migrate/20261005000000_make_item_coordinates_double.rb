class MakeItemCoordinatesDouble < ActiveRecord::Migration[7.2]
  def up
    change_column :items, :latitude, :float, limit: 53
    change_column :items, :longitude, :float, limit: 53
  end

  def down
    change_column :items, :latitude, :float
    change_column :items, :longitude, :float
  end
end
