class AddDeleted < ActiveRecord::Migration[4.2]
  def change
    change_table :items do |t|
      t.boolean :deleted, null: false, default: false
    end
  end
end
