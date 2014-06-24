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

ActiveRecord::Schema.define(version: 20140619111938) do

  create_table "categories", force: true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "categories_queries", force: true do |t|
    t.integer "category_id"
    t.integer "query_id"
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
    t.string   "body"
    t.string   "search_engine"
    t.integer  "max_count",     default: 0
    t.string   "sort",          default: "t"
    t.date     "from"
    t.date     "to"
    t.integer  "g_period_num"
    t.integer  "timeout",       default: 120
    t.boolean  "track",         default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "queries_texts", force: true do |t|
    t.integer "text_id"
    t.integer "query_id"
  end

  create_table "texts", force: true do |t|
    t.string   "title"
    t.text     "content"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
