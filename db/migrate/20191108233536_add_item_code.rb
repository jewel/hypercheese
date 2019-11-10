class AddItemCode < ActiveRecord::Migration[6.0]
  def change
    change_table :items do |t|
      t.string :code
    end
    Item.all.each do |item|
      item.code = SecureRandom.urlsafe_base64 8
      item.save
    end
    change_column :items, :code, :string, null: false, unique: true
  end
end
