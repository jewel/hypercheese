class AddDuration < ActiveRecord::Migration[6.0]
  def change
    change_table :items do |t|
      t.float :duration
    end
  end
end
