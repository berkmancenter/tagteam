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

class Hub < ActiveRecord::Base
  include AuthUtilities
  include ModelExtensions
  include DelegatableRoles
  include TagScopable
  extend FriendlyId

  attr_accessible :title, :description, :tag_prefix, :nickname
  acts_as_authorization_object

  friendly_id :nickname, use: [:slugged, :history]

  before_validation { auto_sanitize_html(:description) }
  after_validation :move_friendly_id_error_to_nickname
  before_save :clean_slug

  acts_as_api do|c|
    c.allow_jsonp_callback = true
  end

  has_many :hub_feeds, dependent: :destroy
  has_many :feeds, through: :hub_feeds
  has_many :republished_feeds, dependent: :destroy, order: 'created_at desc'

  # We want to make sure we're always getting the oldest filter first in this
  # list so if we happen to apply all these in order, it's the correct order.
  has_many :all_tag_filters, class_name: 'TagFilter',
    dependent: :destroy, order: 'updated_at ASC'

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
  alias_method :taggable_items, :feed_items

  def clean_slug
    # work around FriendlyId bug that generates slugs for empty nicknames
    self.slug = nil if nickname.blank?
    true
  end

  def move_friendly_id_error_to_nickname
    errors.add :nickname,
      *errors.delete(:friendly_id) if errors[:friendly_id].present?
  end

  def should_generate_new_friendly_id?
    nickname_changed?
  end

  def display_title
    title
  end
  alias :to_s :display_title

  # Used as the key to track the tag facet for this Hub's tags in a FeedItem.
  def tagging_key
    "hub_#{self.id}".to_sym
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
    ActsAsTaggableOn::Tag.find_by_sql([
      'SELECT tags.*, count(*)
      FROM tags JOIN taggings ON taggings.tag_id = tags.id
      WHERE taggings.context = ? AND taggings.taggable_type = ?
      GROUP BY tags.id ORDER BY count(*) DESC', self.tagging_key, 'FeedItem'])
  end

  def self.top_new_hubs
    self.order('created_at DESC').limit(3)
  end

  def self.most_active_hubs(limit = 4)
    search = FeedItem.search do
      facet :hub_ids, limit: limit
      paginate per_page: 0
    end
    Hub.where(id: search.facet(:hub_ids).rows.map(&:value))
  end

  def self.by_first_owner(dir = 'asc')
    rel = select(%q|"hubs".*, string_agg("users".username,',') as owners|).
      joins("INNER JOIN roles ON roles.authorizable_id = hubs.id
            AND roles.authorizable_type = 'Hub'
            AND roles.name = 'owner'
            INNER JOIN roles_users ON roles_users.role_id = roles.id
            INNER JOIN users ON roles_users.user_id = users.id").
            order('owners').group('hubs.id')
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
end
