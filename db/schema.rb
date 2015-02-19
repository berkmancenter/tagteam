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

ActiveRecord::Schema.define(:version => 20150213205538) do

  create_table "add_tag_filters", :force => true do |t|
    t.integer  "tag_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "add_tag_filters", ["tag_id"], :name => "index_add_tag_filters_on_tag_id"

  create_table "delete_tag_filters", :force => true do |t|
    t.integer  "tag_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "delete_tag_filters", ["tag_id"], :name => "index_delete_tag_filters_on_tag_id"

  create_table "documentations", :force => true do |t|
    t.string   "match_key",   :limit => 100,                       :null => false
    t.string   "title",       :limit => 500,                       :null => false
    t.string   "description", :limit => 1048576
    t.string   "lang",        :limit => 2,       :default => "en"
    t.datetime "created_at",                                       :null => false
    t.datetime "updated_at",                                       :null => false
  end

  add_index "documentations", ["lang"], :name => "index_documentations_on_lang"
  add_index "documentations", ["match_key"], :name => "index_documentations_on_match_key", :unique => true
  add_index "documentations", ["title"], :name => "index_documentations_on_title"

  create_table "feed_items", :force => true do |t|
    t.string   "title",          :limit => 500
    t.string   "url",            :limit => 2048
    t.string   "guid",           :limit => 1024
    t.string   "authors",        :limit => 1024
    t.string   "contributors",   :limit => 1024
    t.string   "description",    :limit => 5120
    t.string   "content",        :limit => 1048576
    t.string   "rights",         :limit => 500
    t.datetime "date_published"
    t.datetime "last_updated"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.text     "image_url"
  end

  add_index "feed_items", ["authors"], :name => "index_feed_items_on_authors"
  add_index "feed_items", ["contributors"], :name => "index_feed_items_on_contributors"
  add_index "feed_items", ["date_published"], :name => "index_feed_items_on_date_published"
  add_index "feed_items", ["url"], :name => "index_feed_items_on_url", :unique => true

  create_table "feed_items_feed_retrievals", :id => false, :force => true do |t|
    t.integer "feed_item_id"
    t.integer "feed_retrieval_id"
  end

  add_index "feed_items_feed_retrievals", ["feed_item_id"], :name => "index_feed_items_feed_retrievals_on_feed_item_id"
  add_index "feed_items_feed_retrievals", ["feed_retrieval_id"], :name => "index_feed_items_feed_retrievals_on_feed_retrieval_id"

  create_table "feed_items_feeds", :id => false, :force => true do |t|
    t.integer "feed_id"
    t.integer "feed_item_id"
  end

  add_index "feed_items_feeds", ["feed_id"], :name => "index_feed_items_feeds_on_feed_id"
  add_index "feed_items_feeds", ["feed_item_id"], :name => "index_feed_items_feeds_on_feed_item_id"

  create_table "feed_retrievals", :force => true do |t|
    t.integer  "feed_id"
    t.boolean  "success"
    t.string   "info",        :limit => 5120
    t.string   "status_code", :limit => 25
    t.string   "changelog",   :limit => 1048576
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  create_table "feeds", :force => true do |t|
    t.string   "title",                    :limit => 500
    t.string   "description",              :limit => 2048
    t.string   "guid",                     :limit => 1024
    t.datetime "last_updated"
    t.datetime "items_changed_at"
    t.string   "rights",                   :limit => 500
    t.string   "authors",                  :limit => 1024
    t.string   "feed_url",                 :limit => 1024,                    :null => false
    t.string   "link",                     :limit => 1024
    t.string   "generator",                :limit => 500
    t.string   "flavor",                   :limit => 25
    t.string   "language",                 :limit => 25
    t.boolean  "bookmarking_feed",                         :default => false
    t.datetime "next_scheduled_retrieval"
    t.datetime "created_at",                                                  :null => false
    t.datetime "updated_at",                                                  :null => false
  end

  add_index "feeds", ["authors"], :name => "index_feeds_on_authors"
  add_index "feeds", ["bookmarking_feed"], :name => "index_feeds_on_bookmarking_feed"
  add_index "feeds", ["feed_url"], :name => "index_feeds_on_feed_url"
  add_index "feeds", ["flavor"], :name => "index_feeds_on_flavor"
  add_index "feeds", ["generator"], :name => "index_feeds_on_generator"
  add_index "feeds", ["guid"], :name => "index_feeds_on_guid"
  add_index "feeds", ["next_scheduled_retrieval"], :name => "index_feeds_on_next_scheduled_retrieval"

  create_table "friendly_id_slugs", :force => true do |t|
    t.string   "slug",                         :null => false
    t.integer  "sluggable_id",                 :null => false
    t.string   "sluggable_type", :limit => 40
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type"], :name => "index_friendly_id_slugs_on_slug_and_sluggable_type", :unique => true
  add_index "friendly_id_slugs", ["sluggable_id"], :name => "index_friendly_id_slugs_on_sluggable_id"
  add_index "friendly_id_slugs", ["sluggable_type"], :name => "index_friendly_id_slugs_on_sluggable_type"

  create_table "hub_feed_item_tag_filters", :force => true do |t|
    t.integer  "hub_id"
    t.integer  "feed_item_id"
    t.string   "filter_type",     :limit => 100, :null => false
    t.integer  "filter_id",                      :null => false
    t.integer  "position"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.string   "created_by_type"
    t.integer  "created_by_id"
  end

  add_index "hub_feed_item_tag_filters", ["feed_item_id"], :name => "index_hub_feed_item_tag_filters_on_feed_item_id"
  add_index "hub_feed_item_tag_filters", ["filter_id"], :name => "index_hub_feed_item_tag_filters_on_filter_id"
  add_index "hub_feed_item_tag_filters", ["filter_type"], :name => "index_hub_feed_item_tag_filters_on_filter_type"
  add_index "hub_feed_item_tag_filters", ["hub_id"], :name => "index_hub_feed_item_tag_filters_on_hub_id"
  add_index "hub_feed_item_tag_filters", ["position"], :name => "index_hub_feed_item_tag_filters_on_position"

  create_table "hub_feed_tag_filters", :force => true do |t|
    t.integer  "hub_feed_id"
    t.string   "filter_type", :limit => 100, :null => false
    t.integer  "filter_id",                  :null => false
    t.integer  "position"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  add_index "hub_feed_tag_filters", ["filter_id"], :name => "index_hub_feed_tag_filters_on_filter_id"
  add_index "hub_feed_tag_filters", ["filter_type"], :name => "index_hub_feed_tag_filters_on_filter_type"
  add_index "hub_feed_tag_filters", ["hub_feed_id"], :name => "index_hub_feed_tag_filters_on_hub_feed_id"
  add_index "hub_feed_tag_filters", ["position"], :name => "index_hub_feed_tag_filters_on_position"

  create_table "hub_feeds", :force => true do |t|
    t.integer  "feed_id",                     :null => false
    t.integer  "hub_id",                      :null => false
    t.string   "title",       :limit => 500
    t.string   "description", :limit => 2048
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
  end

  add_index "hub_feeds", ["feed_id"], :name => "index_hub_feeds_on_feed_id"
  add_index "hub_feeds", ["hub_id", "feed_id"], :name => "index_hub_feeds_on_hub_id_and_feed_id", :unique => true
  add_index "hub_feeds", ["hub_id"], :name => "index_hub_feeds_on_hub_id"

  create_table "hub_tag_filters", :force => true do |t|
    t.integer  "hub_id"
    t.string   "filter_type", :limit => 100, :null => false
    t.integer  "filter_id",                  :null => false
    t.integer  "position"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  add_index "hub_tag_filters", ["filter_id"], :name => "index_hub_tag_filters_on_filter_id"
  add_index "hub_tag_filters", ["filter_type"], :name => "index_hub_tag_filters_on_filter_type"
  add_index "hub_tag_filters", ["hub_id"], :name => "index_hub_tag_filters_on_hub_id"
  add_index "hub_tag_filters", ["position"], :name => "index_hub_tag_filters_on_position"

  create_table "hubs", :force => true do |t|
    t.string   "title",       :limit => 500,  :null => false
    t.string   "description", :limit => 2048
    t.string   "tag_prefix",  :limit => 25
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.string   "nickname"
    t.string   "slug"
    t.text     "tag_count"
  end

  add_index "hubs", ["slug"], :name => "index_hubs_on_slug"
  add_index "hubs", ["tag_prefix"], :name => "index_hubs_on_tag_prefix"
  add_index "hubs", ["title"], :name => "index_hubs_on_title"

  create_table "input_sources", :force => true do |t|
    t.integer  "republished_feed_id",                                   :null => false
    t.integer  "item_source_id",                                        :null => false
    t.string   "item_source_type",    :limit => 100,                    :null => false
    t.string   "effect",              :limit => 25,  :default => "add", :null => false
    t.integer  "position"
    t.integer  "limit"
    t.datetime "created_at",                                            :null => false
    t.datetime "updated_at",                                            :null => false
  end

  add_index "input_sources", ["effect"], :name => "index_input_sources_on_effect"
  add_index "input_sources", ["item_source_id"], :name => "index_input_sources_on_item_source_id"
  add_index "input_sources", ["item_source_type", "item_source_id", "effect", "republished_feed_id"], :name => "bob_the_index", :unique => true
  add_index "input_sources", ["position"], :name => "index_input_sources_on_position"
  add_index "input_sources", ["republished_feed_id"], :name => "index_input_sources_on_republished_feed_id"

  create_table "modify_tag_filters", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "new_tag_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "modify_tag_filters", ["new_tag_id"], :name => "index_modify_tag_filters_on_new_tag_id"
  add_index "modify_tag_filters", ["tag_id"], :name => "index_modify_tag_filters_on_tag_id"

  create_table "republished_feeds", :force => true do |t|
    t.integer  "hub_id"
    t.string   "title",       :limit => 500,                  :null => false
    t.string   "description", :limit => 5120
    t.integer  "limit",                       :default => 50
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.string   "url_key",     :limit => 50,                   :null => false
  end

  add_index "republished_feeds", ["hub_id"], :name => "index_republished_feeds_on_hub_id"
  add_index "republished_feeds", ["title"], :name => "index_republished_feeds_on_title"
  add_index "republished_feeds", ["url_key"], :name => "index_republished_feeds_on_url_key", :unique => true

  create_table "roles", :force => true do |t|
    t.string   "name",              :limit => 40
    t.string   "authorizable_type", :limit => 40
    t.integer  "authorizable_id"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  add_index "roles", ["authorizable_id"], :name => "index_roles_on_authorizable_id"
  add_index "roles", ["authorizable_type"], :name => "index_roles_on_authorizable_type"
  add_index "roles", ["name"], :name => "index_roles_on_name"

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"
  add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"

  create_table "search_remixes", :force => true do |t|
    t.integer  "hub_id"
    t.text     "search_string"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], :name => "taggings_idx", :unique => true
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"
  add_index "taggings", ["taggable_type", "context"], :name => "index_taggings_on_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string  "name"
    t.integer "taggings_count", :default => 0
  end

  add_index "tags", ["name"], :name => "index_tags_on_name", :unique => true

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
    t.datetime "created_at",                                            :null => false
    t.datetime "updated_at",                                            :null => false
    t.string   "username",               :limit => 150
  end

  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["unlock_token"], :name => "index_users_on_unlock_token", :unique => true
  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

end
