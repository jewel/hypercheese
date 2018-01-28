class CreateTagAliases < ActiveRecord::Migration
  def change
    create_table :tag_aliases do |t|
      t.references :user, null: false
      t.references :tag, null: false
      t.string :alias
    end
  end
end
