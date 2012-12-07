class UniqueMd5s < ActiveRecord::Migration
  def change
    add_index :items, :md5, unique: true
  end
end
