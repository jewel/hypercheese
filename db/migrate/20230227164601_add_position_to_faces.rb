class AddPositionToFaces < ActiveRecord::Migration[6.0]
  def change
    change_table :faces do |t|
      t.json :position
    end
  end
end
