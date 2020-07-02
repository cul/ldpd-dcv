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

ActiveRecord::Schema.define(version: 20200707172557) do

  create_table "bookmarks", force: :cascade do |t|
    t.integer  "user_id",       null: false
    t.string   "user_type"
    t.string   "document_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "document_type"
  end

  add_index "bookmarks", ["user_id"], name: "index_bookmarks_on_user_id"

  create_table "nav_links", force: :cascade do |t|
    t.string   "sort_label"
    t.string   "sort_group"
    t.string   "link"
    t.boolean  "external"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id"
  end

  create_table "nyre_projects", force: :cascade do |t|
    t.string "call_number"
    t.string "name"
  end

  add_index "nyre_projects", ["call_number"], name: "index_nyre_projects_on_call_number"

  create_table "searches", force: :cascade do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.string   "user_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id"

  create_table "site_pages", force: :cascade do |t|
    t.string  "slug",                    null: false
    t.string  "title"
    t.integer "columns",     default: 1, null: false
    t.boolean "show_facets"
    t.integer "site_id"
  end

  add_index "site_pages", ["site_id", "slug"], name: "index_site_pages_on_site_id_and_slug", unique: true

  create_table "site_text_blocks", force: :cascade do |t|
    t.string  "sort_label"
    t.text    "markdown"
    t.integer "site_page_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string   "slug",              null: false
    t.string   "title"
    t.string   "persistent_url"
    t.string   "publisher_uri"
    t.string   "image_uri"
    t.string   "repository_id"
    t.string   "layout"
    t.string   "palette"
    t.string   "search_type"
    t.boolean  "restricted"
    t.text     "constraints"
    t.text     "map_search"
    t.text     "date_search"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "alternative_title"
  end

  add_index "sites", ["slug"], name: "index_sites_on_slug", unique: true

  create_table "users", force: :cascade do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.boolean  "is_admin"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.boolean  "guest",                  default: false
    t.string   "provider"
    t.string   "uid"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["provider"], name: "index_users_on_provider"
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  add_index "users", ["uid"], name: "index_users_on_uid"

end
