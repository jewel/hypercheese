class AddAddedToItemTags < ActiveRecord::Migration[4.2]
  def change
    change_table :item_tags do |t|
      t.integer :added_by
      t.datetime :created_at
    end
  end
end
