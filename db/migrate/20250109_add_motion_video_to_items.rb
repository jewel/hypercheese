class AddMotionVideoToItems < ActiveRecord::Migration[7.0]
  def change
    add_column :items, :motion_video_path, :string
    add_index :items, :motion_video_path
  end
end