class AddShowOnHomeToSources < ActiveRecord::Migration[4.2]
  def change
    change_table :sources do |t|
      t.boolean :show_on_home, null: false, default: true
    end
  end
end
