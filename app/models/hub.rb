# frozen_string_literal: true

# A Hub is the highest level of organization in TagTeam.
# It has many HubFeed objects containing FeedItems.
# These FeedItem objects have their ActsAsTaggableOn::Tag objects
# filtered via TagFilter objects, which each maintain their own scope.
#
# A Hub has one more more owners, and owners have the ability to manage
# HubFeed, RepublishedFeed, and many other objects.
#
# If a Hub has a tag_prefix defined, all tags on for FeedItems in this Hub
# will have it applied to them on output. So, if you use "oa." as a
# tag_prefix, all FeedItem tags will be prefixed with "oa." when they
# are published via rss, atom, xml, or json.
#
# The tag_prefix is smart enough not to duplicate itself if it already
# exists on a tag.
#
# Most validations are contained in the ModelExtensions mixin.

class Hub < ApplicationRecord
  include AuthUtilities
  include ModelExtensions
  include DelegatableRoles
  include TagScopable
  extend FriendlyId

  attr_accessible :title, :description, :tag_prefix, :nickname, :slug,
                  :notify_taggers
  acts_as_authorization_object

  friendly_id :nickname, use: %i[slugged history]

  before_validation { auto_sanitize_html(:description) }
  after_validation :move_friendly_id_error_to_nickname
  before_save :clean_slug

  acts_as_api do |c|
    c.allow_jsonp_callback = true
  end

  has_many :hub_feeds, dependent: :destroy
  has_many :feeds, through: :hub_feeds
  has_many :republished_feeds, -> { order(created_at: :desc) }, dependent: :destroy
  has_many :hub_user_notifications, dependent: :destroy
  has_many :hub_approved_tags, dependent: :destroy

  # We want to make sure we're always getting the oldest filter first in this
  # list so if we happen to apply all these in order, it's the correct order.
  has_many :all_tag_filters, -> { order(updated_at: :asc) }, class_name: 'TagFilter', dependent: :destroy

  api_accessible :default do |t|
    t.add :id
    t.add :title
    t.add :description
    t.add :created_at
    t.add :updated_at
  end

  searchable do
    text :title
    text :description
    text :slug
    text :nickname
  end

  def feed_items
    FeedItem.joins(:hubs).where(hubs: { id: id })
  end
  alias taggable_items feed_items

  def clean_slug
    # work around FriendlyId bug that generates slugs for empty nicknames
    self.slug = nil if nickname.blank?
    true
  end

  def move_friendly_id_error_to_nickname
    return if errors[:friendly_id].blank?

    errors.add :nickname, *errors.delete(:friendly_id)
  end

  def should_generate_new_friendly_id?
    nickname_changed?
  end

  def display_title
    title
  end
  alias to_s display_title

  # Used as the key to track the tag facet for this Hub's tags in a FeedItem.
  def tagging_key
    "hub_#{id}".to_sym
  end

  def tag_filters_before(tag_filter)
    all_tag_filters.where('updated_at < ?', tag_filter.updated_at)
  end

  def tag_filters_after(tag_filter)
    all_tag_filters.where('updated_at > ?', tag_filter.updated_at)
  end

  # Exclusive on both ends
  def tag_filters_between(first, last)
    all_tag_filters.where('updated_at > ? AND updated_at < ?',
                          first.updated_at, last.updated_at)
  end

  def apply_tag_filters_after(tag_filter)
    tag_filters_after(tag_filter).each(&:apply)
  end

  def apply_tag_filters_until(tag_filter)
    first_filter = last_applied_tag_filter
    unless first_filter
      first_filter = all_tag_filters.first
      first_filter.apply
    end
    tag_filters_between(first_filter, tag_filter).each(&:apply)
  end

  def last_applied_tag_filter
    all_tag_filters.applied.last
  end

  def tag_counts
    ActsAsTaggableOn::Tag.find_by_sql(
      [
        'SELECT
          ta.*, count(DISTINCT tg.taggable_id)
        FROM
          tags ta
        JOIN
          taggings AS tg ON tg.tag_id = ta.id
        WHERE
          tg.context = ? AND
          tg.taggable_type = ?
        GROUP BY
          ta.id
        ORDER BY count(DISTINCT tg.taggable_id) DESC',
        tagging_key, 'FeedItem'
      ]
    )
  end

  def self.top_new_hubs
    order('created_at DESC').limit(3)
  end

  def self.most_active_hubs(limit = 4)
    search = FeedItem.search do
      facet :hub_ids, limit: limit
      paginate per_page: 0
    end
    Hub.where(id: search.facet(:hub_ids).rows.map(&:value))
  end

  def self.by_first_owner(dir = 'asc')
    rel = select(%q|"hubs".*, string_agg("users".username,',') as owners|)
          .joins("INNER JOIN roles ON roles.authorizable_id = hubs.id
            AND roles.authorizable_type = 'Hub'
            AND roles.name = 'owner'
            INNER JOIN roles_users ON roles_users.role_id = roles.id
            INNER JOIN users ON roles_users.user_id = users.id")
          .order('owners').group('hubs.id')
    return rel.reverse_order if dir == 'desc'
    rel
  end

  def self.title
    'Hub'
  end

  # Used when a new item is created
  def self.apply_all_tag_filters_to_item_async(item)
    item.hubs.each do |hub|
      ApplyTagFilters.perform_async(hub.all_tag_filters.pluck(:id), item.id, true)
    end
  end

  # all tags used in the hub
  def tags
    filters_applied = (
      all_tag_filters.pluck(:tag_id) +
      all_tag_filters.pluck(:new_tag_id) -
      ['', nil]
    ).uniq.join(',')

    tags_hub = ActsAsTaggableOn::Tag.find_by_sql(
      [
        'SELECT
           ta.*
         FROM
           tags AS ta
         JOIN
           taggings AS tg ON tg.tag_id = ta.id
         WHERE
           tg.context = ? AND
           tg.taggable_type = ?
         GROUP BY
           ta.id',
        tagging_key, 'FeedItem'
      ]
    )

    tags_filters = []
    unless filters_applied.empty?
      tags_filters = ActsAsTaggableOn::Tag.find_by_sql(
        [
          'SELECT
             t.*
           FROM
             tags AS t
           WHERE
             t.id IN (' + filters_applied + ')'
        ]
      )
    end

    tags_hub + tags_filters
  end

  # all taggings related to the hub
  def taggings
    ActsAsTaggableOn::Tagging.find_by_sql(
      [
        'SELECT
           t.*
         FROM
           taggings AS t
         WHERE
           t.context = ? AND
           t.taggable_type = ?',
        tagging_key, 'FeedItem'
      ]
    )
  end

  def settings
    {
      tags_delimiter: tags_delimiter_with_default,
      official_tag_prefix: official_tag_prefix_with_default,
      hub_approved_tags: hub_approved_tags,
      suggest_only_approved_tags: suggest_only_approved_tags_with_default
    }
  end

  def tags_delimiter_with_default
    tags_delimiter || ','
  end

  def official_tag_prefix_with_default
    official_tag_prefix || ''
  end

  def suggest_only_approved_tags_with_default
    suggest_only_approved_tags || false
  end

  def hub_feed_for_feed_item(feed_item)
    hub_feeds.find_by(feed: feed_item.feeds)
  end

  def deprecated_tags
    filters = all_tag_filters.select(:tag_id)
                             .where(scope_type: 'Hub')
                             .where.not(new_tag_id: nil)
                             .group(:tag_id).reorder('')

    ActsAsTaggableOn::Tag.where(id: filters.map(&:tag_id))
  end
end
