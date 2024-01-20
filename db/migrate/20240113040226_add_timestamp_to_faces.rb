class AddTimestampToFaces < ActiveRecord::Migration[6.0]
  def change
    change_table :faces do |t|
      t.float :timestamp
    end
  end
end
