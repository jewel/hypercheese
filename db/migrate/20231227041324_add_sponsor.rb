class AddSponsor < ActiveRecord::Migration[6.0]
  def change
    change_table :users do |t|
      t.references :sponsor
    end
  end
end
