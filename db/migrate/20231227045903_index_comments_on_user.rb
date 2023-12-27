class IndexCommentsOnUser < ActiveRecord::Migration[6.0]
  def change
    add_index :comments, :user_id
  end
end
