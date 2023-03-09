class AddAesthetics < ActiveRecord::Migration[6.0]
  def change
    change_table :items do |t|
      t.float :aesthetics_score
    end
  end
end
