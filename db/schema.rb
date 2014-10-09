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

ActiveRecord::Schema.define(version: 20140922123342) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "categories", force: true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "essences", force: true do |t|
    t.string  "title"
    t.integer "rating"
    t.integer "text_id"
  end

  create_table "keyphrases", force: true do |t|
    t.string  "body"
    t.integer "query_id"
  end

  create_table "origins", force: true do |t|
    t.string   "title"
    t.string   "url"
    t.integer  "query_position"
    t.string   "origin_type"
    t.integer  "group",          default: 0
    t.integer  "timeout",        default: 20
    t.boolean  "corrupted",      default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "origins_queries", force: true do |t|
    t.integer "origin_id"
    t.integer "query_id"
  end

  create_table "queries", force: true do |t|
    t.string   "title"
    t.integer  "timeout",     default: 3600
    t.integer  "category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "queries_texts", force: true do |t|
    t.integer "query_id"
    t.integer "text_id"
  end

  create_table "texts", force: true do |t|
    t.string   "title"
    t.text     "description"
    t.text     "content"
    t.string   "author"
    t.string   "url"
    t.text     "guid"
    t.integer  "origin_id"
    t.integer  "emot"
    t.integer  "my_emot"
    t.datetime "datetime"
    t.boolean  "novel",       default: true
    t.datetime "created_at"
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

  add_index "users", ["remember_me_token"], name: "index_users_on_remember_me_token", using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

end
