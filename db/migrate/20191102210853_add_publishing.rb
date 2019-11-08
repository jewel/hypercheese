class AddPublishing < ActiveRecord::Migration[6.0]
  def change
    change_table :sources do |t|
      t.references :user
    end

    change_table :items do |t|
      t.boolean :published, default: true
    end
  end
end
