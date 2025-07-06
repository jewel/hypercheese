class AddFuzzyDateToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :fuzzy_date, :string
  end
end