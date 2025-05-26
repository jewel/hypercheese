class CreateDevices < ActiveRecord::Migration[7.0]
  def change
    create_table :devices do |t|
      t.references :user, null: false
      t.string :uuid, null: false
      t.string :nickname
      t.string :os
      t.string :client_software
      t.string :client_version
      t.datetime :last_manifest_at
      t.datetime :last_upload_at
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :devices, :uuid, unique: true
  end
end
