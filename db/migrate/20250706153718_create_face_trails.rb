class CreateFaceTrails < ActiveRecord::Migration[7.2]
  def change
    create_table :face_trails do |t|
      t.references :item, null: false
      t.decimal :start_timestamp, precision: 10, scale: 3, null: false
      t.decimal :end_timestamp, precision: 10, scale: 3, null: false
      t.decimal :center_x, precision: 8, scale: 3, null: false
      t.decimal :center_y, precision: 8, scale: 3, null: false
      t.decimal :width, precision: 8, scale: 3, null: false
      t.decimal :height, precision: 8, scale: 3, null: false
      t.references :representative_face, null: true, foreign_key: { to_table: :faces }
      t.timestamps
    end

    add_reference :faces, :face_trail, null: true, foreign_key: true
    add_column :faces, :frame_only, :boolean, default: false, null: false
    add_index :face_trails, :item_id
    add_index :faces, :face_trail_id
  end
end