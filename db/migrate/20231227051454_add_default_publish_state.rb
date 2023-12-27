class AddDefaultPublishState < ActiveRecord::Migration[6.0]
  def change
    change_table :sources do |t|
      t.boolean :default_published_state
    end

    Source.where(user_id: nil).update_all default_published_state: true
  end
end
