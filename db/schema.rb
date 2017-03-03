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

ActiveRecord::Schema.define(version: 20161013195312) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "chart_series", force: :cascade do |t|
    t.integer  "chart_id"
    t.text     "group_filter"
    t.text     "entities_filter"
    t.text     "category_filter"
    t.text     "question_filter"
    t.text     "question_options_filter"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "chart_series", ["chart_id"], name: "index_chart_series_on_chart_id", using: :btree

  create_table "charts", force: :cascade do |t|
    t.integer  "user_id"
    t.text     "title"
    t.text     "output"
    t.text     "chart_type"
    t.text     "aggregator_type"
    t.text     "cols"
    t.text     "rows"
    t.text     "years_filter"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "charts", ["user_id"], name: "index_charts_on_user_id", using: :btree

  create_table "content_slugs", force: :cascade do |t|
    t.integer "user_id"
    t.text    "content"
    t.boolean "public"
    t.integer "sizex"
    t.integer "sizey"
    t.boolean "resizeable", default: true
  end

  create_table "dashboard_widgets", force: :cascade do |t|
    t.integer "dashboard_id"
    t.integer "position"
    t.integer "sizex"
    t.integer "sizey"
    t.boolean "resizeable",   default: true
    t.text    "widget_type"
    t.integer "widget_id"
    t.string  "widget_title"
  end

  create_table "dashboards", force: :cascade do |t|
    t.integer "user_id"
    t.text    "theme"
  end

  add_index "dashboards", ["user_id"], name: "index_dashboards_on_user_id", using: :btree

  create_table "data_migrations", force: :cascade do |t|
    t.text "version", null: false
  end

  create_table "permission_groups", force: :cascade do |t|
    t.text     "title",      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "permission_ls_group_filters", force: :cascade do |t|
    t.integer  "permission_ls_group_id",                 null: false
    t.integer  "virtual_question_qid"
    t.text     "ident_type"
    t.text     "restricted_val"
    t.boolean  "filter_all",             default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "permission_ls_group_filters", ["permission_ls_group_id"], name: "uniq_qid_by_group", unique: true, using: :btree

  create_table "permission_ls_groups", force: :cascade do |t|
    t.integer  "virtual_survey_sid",                  null: false
    t.integer  "permission_group_id",                 null: false
    t.boolean  "enabled",             default: false
    t.boolean  "view_raw",            default: false
    t.boolean  "view_all",            default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "permission_ls_groups", ["permission_group_id"], name: "uniq_sid_by_group", unique: true, using: :btree

  create_table "question_widgets", force: :cascade do |t|
    t.integer  "role_aggregate_id"
    t.integer  "lime_question_qid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "agg"
    t.string   "pk"
    t.integer  "user_id"
    t.string   "graph_type"
    t.string   "view_type"
  end

  create_table "role_aggregates", force: :cascade do |t|
    t.string   "pk_fieldname"
    t.integer  "user_id"
    t.integer  "virtual_survey_sid"
    t.text     "agg_fieldname"
    t.text     "pk_title_fieldname"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "view_type"
    t.string   "pk_label"
    t.string   "agg_label"
    t.string   "agg_title_fieldname"
    t.string   "default_view"
  end

  create_table "user_externals", force: :cascade do |t|
    t.integer "user_id",                    null: false
    t.string  "ident"
    t.string  "ident_type",                 null: false
    t.boolean "use_email",  default: false
  end

  add_index "user_externals", ["user_id"], name: "index_user_externals_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "",      null: false
    t.string   "encrypted_password",     default: "",      null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "roles"
    t.string   "username"
    t.datetime "locked_at"
    t.string   "full_name"
    t.boolean  "is_ldap",                default: false
    t.integer  "permission_group_id"
    t.string   "ls_list_state",          default: "dirty"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  create_table "version_notes", force: :cascade do |t|
    t.text     "note"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",       null: false
    t.integer  "item_id",         null: false
    t.string   "event",           null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.text     "object_changes"
    t.integer  "version_note_id"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
  add_index "versions", ["version_note_id"], name: "index_versions_on_version_note_id", using: :btree

end
