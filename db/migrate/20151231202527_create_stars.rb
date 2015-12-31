class CreateStars < ActiveRecord::Migration
  def change
    create_table :stars do |t|
      t.references :user, index: true, null: false
      t.references :item, index: true, null: false
      t.datetime :created_at
    end
  end
end
