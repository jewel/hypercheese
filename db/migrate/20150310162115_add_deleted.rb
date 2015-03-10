class AddDeleted < ActiveRecord::Migration
  def change
    change_table :items do |t|
      t.boolean :deleted, null: false, default: false
    end
  end
end
