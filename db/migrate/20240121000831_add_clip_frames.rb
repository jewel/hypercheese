class AddClipFrames < ActiveRecord::Migration[6.0]
  def change
    create_table :clip_frames do |t|
      t.references :item, null: false
      t.float :aesthetics_score, null: false
      t.float :timestamp, null: false
    end
  end
end
