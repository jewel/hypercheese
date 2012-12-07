# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121207210334) do

  create_table "comments", :force => true do |t|
    t.text     "text"
    t.integer  "user_id"
    t.integer  "item_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "comments", ["item_id"], :name => "index_comments_on_item_id"

  create_table "events", :force => true do |t|
    t.string   "name"
    t.datetime "start"
    t.datetime "finish"
    t.text     "description"
    t.integer  "location_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "groups", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "item_tags", :force => true do |t|
    t.integer "item_id"
    t.integer "tag_id"
  end

  add_index "item_tags", ["item_id"], :name => "index_item_tags_on_item_id"
  add_index "item_tags", ["tag_id"], :name => "index_item_tags_on_tag_id"

  create_table "items", :force => true do |t|
    t.datetime "taken"
    t.text     "description"
    t.string   "type"
    t.string   "path"
    t.string   "md5"
    t.integer  "width"
    t.integer  "height"
    t.integer  "view_count"
    t.integer  "event_id"
    t.integer  "group_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.datetime "deleted_at"
  end

  add_index "items", ["md5"], :name => "index_items_on_md5", :unique => true
  add_index "items", ["taken"], :name => "index_items_on_taken"

  create_table "locations", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "tags", :force => true do |t|
    t.string   "label"
    t.datetime "birthday"
    t.integer  "item_count"
    t.integer  "icon_item_id"
    t.integer  "parent_tag_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "tags", ["label"], :name => "index_tags_on_label"

end
