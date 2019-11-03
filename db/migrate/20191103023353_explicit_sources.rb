class ExplicitSources < ActiveRecord::Migration[6.0]
  def change
    change_table :item_paths do |t|
      t.references :source, null: false
    end
  end
end
