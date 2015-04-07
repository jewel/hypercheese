class CreateShares < ActiveRecord::Migration
  def change
    create_table :shares do |t|
      t.references :user
      t.string :code, null: false
    end

    create_table :share_items do |t|
      t.references :share
      t.references :item
    end
  end
end
