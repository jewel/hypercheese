class CreateRatings < ActiveRecord::Migration[4.2]
  def change
    create_table :ratings do |t|
      t.string :value
      t.references :user
      t.references :item, index: true

      t.timestamps
    end
  end
end
