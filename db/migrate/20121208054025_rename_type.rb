class RenameType < ActiveRecord::Migration[4.2]
  def change
    change_table :items do |t|
      t.remove :type
      t.string :variety
    end
  end
end
