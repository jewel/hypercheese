class AddAddedToItemTags < ActiveRecord::Migration
  def change
    change_table :item_tags do |t|
      t.integer :added_by
      t.datetime :created_at
    end
  end
end
