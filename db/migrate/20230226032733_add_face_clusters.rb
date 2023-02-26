class AddFaceClusters < ActiveRecord::Migration[6.0]
  def change
    change_table :faces do |t|
      t.references :cluster
      t.float :similarity
    end
  end
end
