class CreateStars < ActiveRecord::Migration[4.2]
  def change
    create_table :stars do |t|
      t.references :user, index: true, null: false
      t.references :item, index: true, null: false
      t.datetime :created_at
    end
  end
end
