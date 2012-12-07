class InitialTables < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.datetime :taken
      t.text :description
      t.string :type
      t.string :path
      t.string :md5
      t.integer :width
      t.integer :height
      t.integer :view_count
      t.references :event
      t.references :group

      t.timestamps
      t.datetime :deleted_at
    end
    add_index :items, :taken

    create_table :groups do |t|
      t.timestamps
    end

    create_table :events do |t|
      t.string :name
      t.datetime :start
      t.datetime :finish
      t.text :description
      t.references :location
      t.timestamps
    end

    create_table :comments do |t|
      t.text :text
      t.references :user
      t.references :item
      t.timestamps
    end
    add_index :comments, :item_id

    create_table :locations do |t|
      t.string :name
      t.timestamps
    end

    create_table :tags do |t|
      t.string :label
      t.datetime :birthday
      t.integer :item_count
      t.integer :icon_item_id
      t.integer :parent_tag_id
      t.timestamps
    end
    add_index :tags, :label

    create_table :item_tags do |t|
      t.references :item
      t.references :tag
    end
    add_index :item_tags, :item_id
    add_index :item_tags, :tag_id
  end
end
