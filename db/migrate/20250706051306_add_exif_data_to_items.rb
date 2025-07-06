class AddExifDataToItems < ActiveRecord::Migration[7.2]
  def change
    add_column :items, :exif_data, :text, collation: 'utf8mb4_bin'
    add_check_constraint :items, "json_valid(`exif_data`)", name: "exif_data_valid_json"
  end
end