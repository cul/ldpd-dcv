# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_12_04_183815) do

  create_table "bookmarks", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "user_type"
    t.string "document_id"
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "document_type"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "nav_links", force: :cascade do |t|
    t.string "sort_label"
    t.string "sort_group"
    t.string "link"
    t.boolean "external"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "site_id"
  end

  create_table "nyre_projects", force: :cascade do |t|
    t.string "call_number"
    t.string "name"
    t.index ["call_number"], name: "index_nyre_projects_on_call_number"
  end

  create_table "scope_filters", force: :cascade do |t|
    t.string "filter_type"
    t.string "value"
    t.string "scopeable_type"
    t.integer "scopeable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "searches", force: :cascade do |t|
    t.text "query_params"
    t.integer "user_id"
    t.string "user_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "site_pages", force: :cascade do |t|
    t.string "slug", null: false
    t.string "title"
    t.integer "columns", default: 1, null: false
    t.integer "site_id"
    t.index ["site_id", "slug"], name: "index_site_pages_on_site_id_and_slug", unique: true
  end

  create_table "site_text_blocks", force: :cascade do |t|
    t.string "sort_label"
    t.text "markdown"
    t.integer "site_page_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "slug", null: false
    t.string "title"
    t.string "persistent_url"
    t.string "publisher_uri"
    t.text "image_uris"
    t.string "repository_id"
    t.string "layout"
    t.string "palette"
    t.string "search_type"
    t.boolean "restricted"
    t.text "permissions"
    t.text "map_search"
    t.text "date_search"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "alternative_title"
    t.boolean "show_facets", default: false
    t.text "editor_uids"
    t.text "search_configuration"
    t.index ["slug"], name: "index_sites_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.boolean "is_admin"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.boolean "guest", default: false
    t.string "provider"
    t.string "uid"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider"], name: "index_users_on_provider"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid"], name: "index_users_on_uid"
  end

  add_foreign_key "nav_links", "sites"
  add_foreign_key "site_pages", "sites"
  add_foreign_key "site_text_blocks", "site_pages"
end
