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

ActiveRecord::Schema.define(version: 20170809173959) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "deactivated_taggings", force: :cascade do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type",    limit: 255
    t.integer  "tagger_id"
    t.string   "tagger_type",      limit: 255
    t.integer  "deactivator_id"
    t.string   "deactivator_type", limit: 255
    t.string   "context",          limit: 255
    t.datetime "created_at"
    t.index ["deactivator_id", "deactivator_type"], name: "d_taggings_deactivator_idx", using: :btree
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "d_taggings_idx", using: :btree
    t.index ["taggable_id", "taggable_type", "context"], name: "d_taggings_type_idx", using: :btree
    t.index ["taggable_type", "context"], name: "index_deactivated_taggings_on_taggable_type_and_context", using: :btree
  end

  create_table "documentations", force: :cascade do |t|
    t.string   "match_key",   limit: 100,                    null: false
    t.string   "title",       limit: 500,                    null: false
    t.string   "description", limit: 1048576
    t.string   "lang",        limit: 2,       default: "en"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.index ["lang"], name: "index_documentations_on_lang", using: :btree
    t.index ["match_key"], name: "index_documentations_on_match_key", unique: true, using: :btree
    t.index ["title"], name: "index_documentations_on_title", using: :btree
  end

  create_table "feed_items", force: :cascade do |t|
    t.string   "title",          limit: 500
    t.string   "url",            limit: 2048
    t.string   "guid",           limit: 1024
    t.string   "authors",        limit: 1024
    t.string   "contributors",   limit: 1024
    t.string   "description",    limit: 5120
    t.string   "content",        limit: 1048576
    t.string   "rights",         limit: 500
    t.datetime "date_published"
    t.datetime "last_updated"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.text     "image_url"
    t.index ["authors"], name: "index_feed_items_on_authors", using: :btree
    t.index ["contributors"], name: "index_feed_items_on_contributors", using: :btree
    t.index ["date_published"], name: "index_feed_items_on_date_published", using: :btree
    t.index ["url"], name: "index_feed_items_on_url", unique: true, using: :btree
  end

  create_table "feed_items_feed_retrievals", id: false, force: :cascade do |t|
    t.integer "feed_item_id"
    t.integer "feed_retrieval_id"
    t.index ["feed_item_id"], name: "index_feed_items_feed_retrievals_on_feed_item_id", using: :btree
    t.index ["feed_retrieval_id"], name: "index_feed_items_feed_retrievals_on_feed_retrieval_id", using: :btree
  end

  create_table "feed_items_feeds", id: false, force: :cascade do |t|
    t.integer "feed_id"
    t.integer "feed_item_id"
    t.index ["feed_id"], name: "index_feed_items_feeds_on_feed_id", using: :btree
    t.index ["feed_item_id"], name: "index_feed_items_feeds_on_feed_item_id", using: :btree
  end

  create_table "feed_retrievals", force: :cascade do |t|
    t.integer  "feed_id"
    t.boolean  "success"
    t.string   "info",        limit: 5120
    t.string   "status_code", limit: 25
    t.string   "changelog",   limit: 1048576
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "feed_subscribers", force: :cascade do |t|
    t.string   "route"
    t.string   "ip",         limit: 15
    t.string   "user_agent"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.index ["route", "ip", "user_agent"], name: "feed_subscribers_uniq_comb", unique: true, using: :btree
  end

  create_table "feed_visitors", force: :cascade do |t|
    t.string   "route"
    t.string   "ip",         limit: 15
    t.string   "user_agent"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "feeds", force: :cascade do |t|
    t.string   "title",                    limit: 500
    t.string   "description",              limit: 2048
    t.string   "guid",                     limit: 1024
    t.datetime "last_updated"
    t.datetime "items_changed_at"
    t.string   "rights",                   limit: 500
    t.string   "authors",                  limit: 1024
    t.string   "feed_url",                 limit: 1024,                 null: false
    t.string   "link",                     limit: 1024
    t.string   "generator",                limit: 500
    t.string   "flavor",                   limit: 25
    t.string   "language",                 limit: 25
    t.boolean  "bookmarking_feed",                      default: false
    t.datetime "next_scheduled_retrieval"
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.index ["authors"], name: "index_feeds_on_authors", using: :btree
    t.index ["bookmarking_feed"], name: "index_feeds_on_bookmarking_feed", using: :btree
    t.index ["feed_url"], name: "index_feeds_on_feed_url", using: :btree
    t.index ["flavor"], name: "index_feeds_on_flavor", using: :btree
    t.index ["generator"], name: "index_feeds_on_generator", using: :btree
    t.index ["guid"], name: "index_feeds_on_guid", using: :btree
    t.index ["next_scheduled_retrieval"], name: "index_feeds_on_next_scheduled_retrieval", using: :btree
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",           limit: 255, null: false
    t.integer  "sluggable_id",               null: false
    t.string   "sluggable_type", limit: 40
    t.datetime "created_at"
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", unique: true, using: :btree
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree
  end

  create_table "hub_approved_tags", force: :cascade do |t|
    t.integer "hub_id"
    t.string  "tag"
    t.index ["hub_id"], name: "index_hub_approved_tags_on_hub_id", using: :btree
    t.index ["tag"], name: "index_hub_approved_tags_on_tag", using: :btree
  end

  create_table "hub_feeds", force: :cascade do |t|
    t.integer  "feed_id",                  null: false
    t.integer  "hub_id",                   null: false
    t.string   "title",       limit: 500
    t.string   "description", limit: 2048
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.index ["feed_id"], name: "index_hub_feeds_on_feed_id", using: :btree
    t.index ["hub_id", "feed_id"], name: "index_hub_feeds_on_hub_id_and_feed_id", unique: true, using: :btree
    t.index ["hub_id"], name: "index_hub_feeds_on_hub_id", using: :btree
  end

  create_table "hub_user_notifications", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "hub_id"
    t.boolean  "notify_about_modifications"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["hub_id"], name: "index_hub_user_notifications_on_hub_id", using: :btree
    t.index ["user_id"], name: "index_hub_user_notifications_on_user_id", using: :btree
  end

  create_table "hubs", force: :cascade do |t|
    t.string   "title",                                      limit: 500,  null: false
    t.string   "description",                                limit: 2048
    t.string   "tag_prefix",                                 limit: 25
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
    t.string   "nickname",                                   limit: 255
    t.string   "slug",                                       limit: 255
    t.text     "tag_count"
    t.boolean  "notify_taggers"
    t.boolean  "allow_taggers_to_sign_up_for_notifications"
    t.string   "tags_delimiter"
    t.string   "official_tag_prefix"
    t.string   "suggest_only_approved_tags"
    t.index ["slug"], name: "index_hubs_on_slug", using: :btree
    t.index ["tag_prefix"], name: "index_hubs_on_tag_prefix", using: :btree
    t.index ["title"], name: "index_hubs_on_title", using: :btree
  end

  create_table "input_sources", force: :cascade do |t|
    t.integer  "republished_feed_id",                             null: false
    t.integer  "item_source_id",                                  null: false
    t.string   "item_source_type",    limit: 100,                 null: false
    t.string   "effect",              limit: 25,  default: "add", null: false
    t.integer  "position"
    t.integer  "limit"
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.integer  "created_by_only_id"
    t.index ["effect"], name: "index_input_sources_on_effect", using: :btree
    t.index ["item_source_id"], name: "index_input_sources_on_item_source_id", using: :btree
    t.index ["item_source_type", "item_source_id", "effect", "republished_feed_id", "created_by_only_id"], name: "bob_the_index", unique: true, using: :btree
    t.index ["position"], name: "index_input_sources_on_position", using: :btree
    t.index ["republished_feed_id"], name: "index_input_sources_on_republished_feed_id", using: :btree
  end

  create_table "republished_feeds", force: :cascade do |t|
    t.integer  "hub_id"
    t.string   "title",       limit: 500,               null: false
    t.string   "description", limit: 5120
    t.integer  "limit",                    default: 50
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "url_key",     limit: 50,                null: false
    t.index ["hub_id"], name: "index_republished_feeds_on_hub_id", using: :btree
    t.index ["title"], name: "index_republished_feeds_on_title", using: :btree
    t.index ["url_key"], name: "index_republished_feeds_on_url_key", unique: true, using: :btree
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name",              limit: 40
    t.string   "authorizable_type", limit: 40
    t.integer  "authorizable_id"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.index ["authorizable_id"], name: "index_roles_on_authorizable_id", using: :btree
    t.index ["authorizable_type"], name: "index_roles_on_authorizable_type", using: :btree
    t.index ["name"], name: "index_roles_on_name", using: :btree
  end

  create_table "roles_users", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["role_id"], name: "index_roles_users_on_role_id", using: :btree
    t.index ["user_id"], name: "index_roles_users_on_user_id", using: :btree
  end

  create_table "search_remixes", force: :cascade do |t|
    t.integer  "hub_id"
    t.text     "search_string"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "tag_filters", force: :cascade do |t|
    t.integer  "hub_id",                                 null: false
    t.integer  "tag_id",                                 null: false
    t.integer  "new_tag_id"
    t.integer  "scope_id"
    t.string   "scope_type", limit: 255
    t.boolean  "applied",                default: false
    t.string   "type",       limit: 255
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.index ["hub_id"], name: "index_tag_filters_on_hub_id", using: :btree
    t.index ["new_tag_id"], name: "index_tag_filters_on_new_tag_id", using: :btree
    t.index ["scope_type", "scope_id"], name: "index_tag_filters_on_scope_type_and_scope_id", using: :btree
    t.index ["tag_id"], name: "index_tag_filters_on_tag_id", using: :btree
    t.index ["type"], name: "index_tag_filters_on_type", using: :btree
  end

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type", limit: 255
    t.integer  "tagger_id"
    t.string   "tagger_type",   limit: 255
    t.string   "context",       limit: 255
    t.datetime "created_at"
    t.index ["context"], name: "index_taggings_on_context", using: :btree
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, using: :btree
    t.index ["tag_id"], name: "index_taggings_on_tag_id", using: :btree
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy", using: :btree
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id", using: :btree
    t.index ["taggable_type", "context"], name: "index_taggings_on_taggable_type_and_context", using: :btree
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type", using: :btree
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type", using: :btree
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id", using: :btree
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", limit: 255
    t.index ["name"], name: "index_tags_on_name", unique: true, using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "first_name",             limit: 100
    t.string   "last_name",              limit: 100
    t.string   "url",                    limit: 250
    t.string   "email",                  limit: 255, default: "",    null: false
    t.string   "encrypted_password",     limit: 128, default: "",    null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "failed_attempts",                    default: 0
    t.string   "unlock_token",           limit: 255
    t.datetime "locked_at"
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.string   "username",               limit: 150
    t.string   "unconfirmed_email"
    t.boolean  "approved",                           default: false, null: false
    t.text     "signup_reason"
    t.index ["approved"], name: "index_users_on_approved", using: :btree
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree
    t.index ["username"], name: "index_users_on_username", unique: true, using: :btree
  end

end
