class AddFaces < ActiveRecord::Migration[6.0]
  def change
    create_table :faces do |t|
      t.references :item, null: false
      t.references :tag
    end
    change_table :items do |t|
      t.integer :face_count, limit: 4
    end
  end
end
