class IndexItemTagsOnUser < ActiveRecord::Migration[6.0]
  def change
    add_index :item_tags, :user_id
  end
end
