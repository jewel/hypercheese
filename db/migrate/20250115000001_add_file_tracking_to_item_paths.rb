class AddFileTrackingToItemPaths < ActiveRecord::Migration[7.2]
  def change
    add_column :item_paths, :mtime, :datetime
    add_column :item_paths, :size, :bigint
    add_index :item_paths, [:source_id, :path, :mtime], name: 'index_item_paths_on_source_path_mtime'
  end
end