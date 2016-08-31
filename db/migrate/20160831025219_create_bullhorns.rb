class CreateBullhorns < ActiveRecord::Migration
  def change
    create_table :bullhorns do |t|
      t.references :user, index: true, null: false
      t.references :item, index: true, null: false
      t.datetime :created_at
    end

    execute "insert into bullhorns select * from stars"
  end
end
