class UniqueMd5s < ActiveRecord::Migration[4.2]
  def change
    add_index :items, :md5, unique: true
  end
end
