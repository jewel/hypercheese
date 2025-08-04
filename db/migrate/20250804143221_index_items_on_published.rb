class IndexItemsOnPublished < ActiveRecord::Migration[7.2]
  def change
    add_index :items, :published
  end
end
