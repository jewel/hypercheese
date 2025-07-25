# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_07_06_223420) do
  create_table "bullhorns", id: :integer, charset: "latin1", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "item_id", null: false
    t.datetime "created_at", precision: nil
    t.index ["item_id"], name: "index_bullhorns_on_item_id"
    t.index ["user_id"], name: "index_bullhorns_on_user_id"
  end

  create_table "cheese_blobs", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "device_id", null: false
    t.string "path", null: false
    t.string "sha256", null: false
    t.bigint "size", null: false
    t.datetime "mtime", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_cheese_blobs_on_device_id"
    t.index ["sha256"], name: "index_cheese_blobs_on_sha256"
    t.index ["user_id", "device_id", "path"], name: "index_cheese_blobs_on_user_id_and_device_id_and_path", unique: true
    t.index ["user_id"], name: "index_cheese_blobs_on_user_id"
  end

  create_table "clip_frames", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.float "aesthetics_score", null: false
    t.float "timestamp", null: false
    t.index ["item_id"], name: "index_clip_frames_on_item_id"
  end

  create_table "comments", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "text", size: :medium
    t.integer "user_id"
    t.integer "item_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["item_id"], name: "index_comments_on_item_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "delayed_jobs", charset: "utf8mb3", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "devices", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "uuid", null: false
    t.string "nickname"
    t.string "os"
    t.string "client_software"
    t.string "client_version"
    t.datetime "last_manifest_at"
    t.datetime "last_upload_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_devices_on_user_id"
    t.index ["uuid"], name: "index_devices_on_uuid", unique: true
  end

  create_table "events", id: :integer, charset: "latin1", force: :cascade do |t|
    t.string "name"
    t.datetime "start", precision: nil
    t.datetime "finish", precision: nil
    t.text "description"
    t.integer "location_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "faces", charset: "latin1", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "tag_id"
    t.bigint "cluster_id"
    t.float "similarity"
    t.json "position"
    t.integer "confirmed_by"
    t.datetime "confirmed_at", precision: nil
    t.boolean "indexed_in_annoy", default: false
    t.float "timestamp"
    t.index ["cluster_id"], name: "index_faces_on_cluster_id"
    t.index ["item_id"], name: "index_faces_on_item_id"
    t.index ["tag_id"], name: "index_faces_on_tag_id"
  end

  create_table "groups", id: :integer, charset: "latin1", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "item_locations", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "location_id", null: false
    t.index ["item_id"], name: "index_item_locations_on_item_id"
    t.index ["location_id"], name: "index_item_locations_on_location_id"
  end

  create_table "item_paths", id: :integer, charset: "latin1", force: :cascade do |t|
    t.string "path"
    t.integer "item_id"
    t.bigint "source_id", null: false
    t.index ["item_id"], name: "index_item_paths_on_item_id"
    t.index ["path"], name: "index_item_paths_on_path", unique: true
    t.index ["source_id"], name: "index_item_paths_on_source_id"
  end

  create_table "item_places", charset: "utf8mb3", force: :cascade do |t|
    t.integer "item_id", null: false
    t.integer "place_id", null: false
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.index ["item_id", "place_id"], name: "index_item_places_on_item_id_and_place_id", unique: true
    t.index ["item_id"], name: "index_item_places_on_item_id"
    t.index ["place_id"], name: "index_item_places_on_place_id"
    t.index ["user_id"], name: "index_item_places_on_user_id"
  end

  create_table "item_tags", id: :integer, charset: "latin1", force: :cascade do |t|
    t.integer "item_id"
    t.integer "tag_id"
    t.integer "added_by"
    t.datetime "created_at", precision: nil
    t.index ["added_by"], name: "index_item_tags_on_added_by"
    t.index ["item_id"], name: "index_item_tags_on_item_id"
    t.index ["tag_id"], name: "index_item_tags_on_tag_id"
  end

  create_table "items", id: :integer, charset: "latin1", force: :cascade do |t|
    t.datetime "taken", precision: nil
    t.text "description"
    t.string "md5"
    t.integer "width"
    t.integer "height"
    t.integer "view_count"
    t.integer "event_id"
    t.integer "group_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.string "variety"
    t.boolean "deleted", default: false, null: false
    t.boolean "published", default: true
    t.string "code", null: false
    t.integer "face_count"
    t.float "aesthetics_score"
    t.float "latitude"
    t.float "longitude"
    t.float "duration"
    t.index ["md5"], name: "index_items_on_md5", unique: true
    t.index ["taken"], name: "index_items_on_taken"
  end

  create_table "locations", charset: "utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.string "geoid", null: false
    t.json "properties", null: false
    t.index ["geoid"], name: "index_locations_on_geoid"
    t.index ["name"], name: "index_locations_on_name"
  end

  create_table "places", charset: "utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "latitude", precision: 10, scale: 6, null: false
    t.decimal "longitude", precision: 10, scale: 6, null: false
    t.decimal "radius", precision: 8, scale: 2, null: false
    t.integer "created_by", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by"], name: "index_places_on_created_by"
    t.index ["latitude", "longitude"], name: "index_places_on_latitude_and_longitude"
    t.index ["name"], name: "index_places_on_name"
  end

  create_table "ratings", id: :integer, charset: "latin1", force: :cascade do |t|
    t.string "value"
    t.integer "user_id"
    t.integer "item_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["item_id"], name: "index_ratings_on_item_id"
  end

  create_table "search_histories", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "user_id"
    t.string "query", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_search_histories_on_user_id"
  end

  create_table "share_items", id: :integer, charset: "latin1", force: :cascade do |t|
    t.integer "share_id"
    t.integer "item_id"
  end

  create_table "shares", id: :integer, charset: "latin1", force: :cascade do |t|
    t.integer "user_id"
    t.string "code", null: false
  end

  create_table "sources", id: :integer, charset: "latin1", force: :cascade do |t|
    t.string "label"
    t.string "path"
    t.boolean "show_on_home", default: true, null: false
    t.bigint "user_id"
    t.boolean "default_published_state"
    t.bigint "device_id"
    t.index ["device_id"], name: "index_sources_on_device_id"
    t.index ["user_id"], name: "index_sources_on_user_id"
  end

  create_table "stars", id: :integer, charset: "latin1", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "item_id", null: false
    t.datetime "created_at", precision: nil
    t.index ["item_id"], name: "index_stars_on_item_id"
    t.index ["user_id"], name: "index_stars_on_user_id"
  end

  create_table "tag_aliases", id: :integer, charset: "latin1", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "tag_id", null: false
    t.string "alias"
  end

  create_table "tags", id: :integer, charset: "latin1", force: :cascade do |t|
    t.string "label"
    t.datetime "birthday", precision: nil
    t.integer "item_count"
    t.integer "icon_item_id"
    t.integer "parent_tag_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["label"], name: "index_tags_on_label"
  end

  create_table "users", id: :integer, charset: "latin1", force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "role"
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.string "username"
    t.bigint "sponsor_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["sponsor_id"], name: "index_users_on_sponsor_id"
    t.index ["username"], name: "index_users_on_username", unique: true
  end
end
