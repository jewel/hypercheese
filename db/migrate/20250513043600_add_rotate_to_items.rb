class AddRotateToItems < ActiveRecord::Migration[7.2]
  def change
    change_table :items do |t|
      t.integer :rotate, default: 0
    end
  end
end