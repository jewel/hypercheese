class AddCreatedAtIndexes < ActiveRecord::Migration[7.2]
  def change
    add_index :items, :created_at
    add_index :item_tags, :created_at
  end
end
