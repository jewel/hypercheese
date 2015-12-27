class CreateSources < ActiveRecord::Migration
  def change
    create_table :sources do |t|
      t.string :label
      t.string :path
    end
  end
end
