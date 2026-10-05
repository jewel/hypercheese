class AddGpsAccuracyToItems < ActiveRecord::Migration[7.2]
  def change
    add_column :items, :gps_accuracy, :float
  end
end
