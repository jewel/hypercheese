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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151224155156) do

  create_table "comments", force: :cascade do |t|
    t.text     "text"
    t.integer  "user_id"
    t.integer  "item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "comments", ["item_id"], name: "index_comments_on_item_id"

  create_table "events", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.datetime "start"
    t.datetime "finish"
    t.text     "description"
    t.integer  "location_id"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "item_paths", force: :cascade do |t|
    t.string  "path",    limit: 255
    t.integer "item_id"
  end

  create_table "item_tags", force: :cascade do |t|
    t.integer  "item_id"
    t.integer  "tag_id"
    t.integer  "added_by"
    t.datetime "created_at"
  end

  add_index "item_tags", ["item_id"], name: "index_item_tags_on_item_id"
  add_index "item_tags", ["tag_id"], name: "index_item_tags_on_tag_id"

  create_table "items", force: :cascade do |t|
    t.datetime "taken"
    t.text     "description"
    t.string   "md5",         limit: 255
    t.integer  "width"
    t.integer  "height"
    t.integer  "view_count"
    t.integer  "event_id"
    t.integer  "group_id"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.datetime "deleted_at"
    t.string   "variety",     limit: 255
    t.boolean  "deleted",                 default: false, null: false
  end

  add_index "items", ["md5"], name: "index_items_on_md5", unique: true
  add_index "items", ["taken"], name: "index_items_on_taken"

  create_table "locations", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "share_items", force: :cascade do |t|
    t.integer "share_id"
    t.integer "item_id"
  end

  create_table "shares", force: :cascade do |t|
    t.integer "user_id"
    t.string  "code",    limit: 255, null: false
  end

  create_table "tags", force: :cascade do |t|
    t.string   "label",         limit: 255
    t.datetime "birthday"
    t.integer  "item_count"
    t.integer  "icon_item_id"
    t.integer  "parent_tag_id"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "tags", ["label"], name: "index_tags_on_label"

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "role",                   limit: 255
    t.string   "provider",               limit: 255
    t.string   "uid",                    limit: 255
    t.string   "name",                   limit: 255
    t.string   "username"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  add_index "users", ["username"], name: "index_users_on_username", unique: true

end
