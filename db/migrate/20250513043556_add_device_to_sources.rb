class AddDeviceToSources < ActiveRecord::Migration[7.2]
  def change
    add_reference :sources, :device, null: true
  end
end
