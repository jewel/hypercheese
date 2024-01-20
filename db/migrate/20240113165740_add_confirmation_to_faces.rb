class AddConfirmationToFaces < ActiveRecord::Migration[6.0]
  def change
    change_table :faces do |t|
      t.integer :confirmed_by
      t.datetime :confirmed_at
    end
  end
end
