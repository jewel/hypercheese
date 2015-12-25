class AddIndexToItemPaths < ActiveRecord::Migration
  def change
    change_table :item_paths do |t|
      t.index :item_id
      t.index :path, unique: true
    end
  end
end
