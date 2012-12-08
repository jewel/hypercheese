class RenameType < ActiveRecord::Migration
  def change
    change_table :items do |t|
      t.remove :type
      t.string :variety
    end
  end
end
