class MakeCheeseBlobs < ActiveRecord::Migration[6.0]
  def change
    create_table :cheese_blobs do |t|
      t.references :user, null: false
      t.references :device, null: false
      t.string :path, null: false
      t.string :sha256, null: false
      t.bigint :size, null: false
      t.datetime :mtime, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :cheese_blobs, [:user_id, :device_id, :path], unique: true
    add_index :cheese_blobs, :sha256
  end
end
