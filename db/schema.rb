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

ActiveRecord::Schema.define(version: 20140715143840) do

  create_table "categories", force: true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority"

  create_table "essences", force: true do |t|
    t.string   "title"
    t.integer  "rating"
    t.integer  "text_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "queries", force: true do |t|
    t.string   "title"
    t.string   "body"
    t.integer  "max_count",        default: 0
    t.string   "sort",             default: "t"
    t.date     "from"
    t.date     "to"
    t.integer  "g_period_num"
    t.integer  "timeout",          default: 3600
    t.boolean  "track",            default: false
    t.integer  "search_engine_id"
    t.integer  "category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "query_search_engines", force: true do |t|
    t.integer  "query_id"
    t.integer  "search_engine_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "search_engines", force: true do |t|
    t.string   "title"
    t.string   "engine_type",   default: "google"
    t.integer  "timeout",       default: 120
    t.integer  "tracked_count", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "texts", force: true do |t|
    t.string   "title"
    t.text     "content",          limit: 16777215
    t.string   "url"
    t.integer  "query_id"
    t.integer  "search_engine_id"
    t.boolean  "novel",                             default: true
    t.integer  "emot"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "my_emot"
  end

  create_table "users", force: true do |t|
    t.string   "username",                     null: false
    t.string   "crypted_password",             null: false
    t.string   "salt",                         null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_me_token"
    t.datetime "remember_me_token_expires_at"
  end

  add_index "users", ["remember_me_token"], name: "index_users_on_remember_me_token"
  add_index "users", ["username"], name: "index_users_on_username", unique: true

end
