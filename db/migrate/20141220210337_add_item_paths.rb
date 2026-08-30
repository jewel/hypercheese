class AddItemPaths < ActiveRecord::Migration[4.2]
  def change
    create_table :item_paths do |t|
      t.string :path
      t.references :item
    end

    change_table :items do |t|
      t.remove :path
    end
  end
end
