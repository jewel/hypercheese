class AddDeviceToSources < ActiveRecord::Migration[8.0]
  def change
    add_reference :sources, :device, null: true
  end
end
