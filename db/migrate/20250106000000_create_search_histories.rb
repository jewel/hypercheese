class CreateSearchHistories < ActiveRecord::Migration[7.0]
  def change
    create_table :search_histories do |t|
      t.references :user, null: true, foreign_key: true
      t.string :query, null: false
      t.integer :result_count, default: 0
      t.datetime :searched_at, null: false

      t.timestamps
    end

    add_index :search_histories, [:user_id, :searched_at]
    add_index :search_histories, :query
  end
end