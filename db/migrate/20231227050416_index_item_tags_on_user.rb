class IndexItemTagsOnUser < ActiveRecord::Migration[6.0]
  def change
    add_index :item_tags, :added_by
  end
end
