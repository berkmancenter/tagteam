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

ActiveRecord::Schema.define(:version => 20110726122511) do

  create_table "feed_items", :force => true do |t|
    t.integer  "feed_id"
    t.integer  "feed_retrieval_id"
    t.string   "title"
    t.string   "url"
    t.string   "author"
    t.string   "description"
    t.string   "content"
    t.string   "copyright"
    t.datetime "date_published"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "feed_retrievals", :force => true do |t|
    t.integer  "feed_id"
    t.string   "url"
    t.string   "content"
    t.boolean  "success"
    t.string   "status_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "feeds", :force => true do |t|
    t.string   "title"
    t.string   "description"
    t.string   "flavor"
    t.string   "url"
    t.string   "feed_url"
    t.string   "etag"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "feeds_hub_feeds", :id => false, :force => true do |t|
    t.integer "feed_id"
    t.integer "hub_feed_id"
  end

  add_index "feeds_hub_feeds", ["feed_id"], :name => "index_feeds_hub_feeds_on_feed_id"
  add_index "feeds_hub_feeds", ["hub_feed_id"], :name => "index_feeds_hub_feeds_on_hub_feed_id"

  create_table "hub_feeds", :force => true do |t|
    t.integer  "feed_id"
    t.string   "title"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "hub_feeds", ["feed_id"], :name => "index_hub_feeds_on_feed_id"

  create_table "hubs", :force => true do |t|
    t.string   "title",                     :null => false
    t.string   "description"
    t.string   "tag_prefix",  :limit => 25
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "hubs", ["title"], :name => "index_hubs_on_title"

  create_table "roles", :force => true do |t|
    t.string   "name",              :limit => 40
    t.string   "authorizable_type", :limit => 40
    t.integer  "authorizable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["authorizable_id"], :name => "index_roles_on_authorizable_id"
  add_index "roles", ["authorizable_type"], :name => "index_roles_on_authorizable_type"
  add_index "roles", ["name"], :name => "index_roles_on_name"

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"
  add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "first_name",             :limit => 100
    t.string   "last_name",              :limit => 100
    t.string   "url",                    :limit => 250
    t.string   "email",                                 :default => "", :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "failed_attempts",                       :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["unlock_token"], :name => "index_users_on_unlock_token", :unique => true

end
