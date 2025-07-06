class CreateVideoSpeedSegments < ActiveRecord::Migration[7.0]
  def change
    create_table :video_speed_segments do |t|
      t.references :item, null: false, foreign_key: true
      t.decimal :start_time, precision: 10, scale: 3, null: false
      t.decimal :end_time, precision: 10, scale: 3, null: false
      t.decimal :playback_rate, precision: 5, scale: 2, null: false, default: 1.0
      t.string :source_type, default: 'extracted'
      t.text :metadata
      t.timestamps
    end

    add_index :video_speed_segments, [:item_id, :start_time]
    add_index :video_speed_segments, [:item_id, :end_time]
  end
end