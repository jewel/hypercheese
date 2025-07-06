class AddPrecisionToItems < ActiveRecord::Migration[7.2]
  def change
    add_column :items, :precision, :float, comment: "Fuzzy location radius in meters"
  end
end