# frozen_string_literal: true
# A HubFeed links a Hub with a Feed. A Hub has many HubFeeds.
#
# A HubFeed inherits most its metadata from its parent Feed, but a Hub
# owner can override the title and description by editing the HubFeed.
#
# Most validations are contained in the ModelExtensions mixin.

class HubFeed < ApplicationRecord
  include ModelExtensions
  include AuthUtilities
  include TagScopable

  acts_as_authorization_object
  acts_as_api do |c|
    c.allow_jsonp_callback = true
  end

  belongs_to :hub, optional: true
  belongs_to :feed, optional: true
  has_many :feed_items, through: :feed
  has_many :owner_roles, -> { where(authorizable_type: 'HubFeed', name: 'owner') }, foreign_key: :authorizable_id, class_name: 'Role'
  has_many :owners, through: :owner_roles, source: :users

  before_validation do
    auto_sanitize_html(:description)
  end
  validates :feed_id, uniqueness: { scope: :hub_id }
  validates :feed_id, :hub_id, presence: true

  scope :bookmark_collections, -> { includes(:feed).where('feeds.bookmarking_feed' => true) }
  scope :rss, -> { joins(:feed).where('feeds.bookmarking_feed' => false) }
  scope :need_updating, -> { joins(:feed).where(['feeds.next_scheduled_retrieval <= ? AND bookmarking_feed IS false', Time.current]) }
  scope :by_hub, ->(hub_id) { where(hub_id: hub_id) }

  attr_accessible :title, :description

  delegate :most_recent_tagging, to: :feed

  api_accessible :default do |t|
    t.add :id
    t.add :display_title, as: :title
    t.add :display_description, as: :description
    t.add :link
    t.add :hub
    t.add :feed
  end

  # TODO: Review
  # If a new HubFeed gets created, we need to ensure that the tag facets on
  # the feed items it contains (whether those items exist already
  # in TagTeam or not) are calculated.
  after_create do
    feed.solr_index
    # Sidekiq::Client.enqueue(HubFeedFeedItemTagRenderer, self.id)
  end

  after_destroy do
    # Clean up any input_sources that might've been using the feed
    # this points to.
    InputSource.joins(:republished_feed)
               .where('republished_feeds.hub_id' => hub_id)
               .where(item_source_type: 'Feed', item_source_id: feed_id)
               .destroy_all

    # Clean up feed_item input sources
    InputSource.joins(:republished_feed)
               .where('republished_feeds.hub_id' => hub_id)
               .where(item_source_type: 'FeedItem',
                      item_source_id: feed.feed_items.pluck(:id))
               .destroy_all

    # TODO: Review
    # self.feed.solr_index
    # feed_items_of_concern = self.feed.feed_items.collect{|fi| fi.id}
    # tagging_key = self.hub.tagging_key.to_s
    # Sidekiq::Client.enqueue(
    #  ReindexFeedItemsAfterHubFeedDestroyed, feed_items_of_concern, tagging_key)
    # Sidekiq::Client.enqueue(ReindexFeedRetrievals, self.feed.id)
  end

  searchable(include: [:hub]) do
    text :display_title, :display_description,
         :link, :guid, :rights, :authors, :feed_url, :generator

    integer :hub_ids, multiple: true
    integer :feed_item_ids, multiple: true

    string :title
    string :guid
    string :rights
    string :authors
    string :feed_url
    string :link
    string :generator
    string :flavor
    string :language
    time :last_updated
  end

  alias taggable_items feed_items

  def hub_ids
    [hub_id]
  end

  def title
    if self[:title].blank?
      feed ? feed.title : ''
    else
      self[:title]
    end
  end
  alias display_title title
  alias to_s title

  def author_title
    self.owners.any? ? "#{self.owners.first.username}'s tagged items" : "#{self.title} tagged items"
  end

  def display_description
    description.blank? ? feed.description : description
  end

  # Inherited from this HubFeed's feed.
  delegate :link, to: :feed

  # Inherited from this HubFeed's feed.
  delegate :guid, to: :feed

  # Inherited from this HubFeed's feed.
  delegate :rights, to: :feed

  # Inherited from this HubFeed's feed.
  delegate :authors, to: :feed

  # Inherited from this HubFeed's feed.
  delegate :feed_url, to: :feed

  # Inherited from this HubFeed's feed.
  delegate :generator, to: :feed

  # Inherited from this HubFeed's feed.
  delegate :last_updated, to: :feed

  # Inherited from this HubFeed's feed.
  delegate :flavor, to: :feed

  # Inherited from this HubFeed's feed.
  delegate :language, to: :feed

  def latest_successful_feed_retrieval
    feed.feed_retrievals.successful.last
  end

  def latest_feed_retrieval
    feed.feed_retrievals.last
  rescue Exception => e
    logger.warn(e.inspect)
    []
  end

  def latest_feed_items(limit = 15)
    search = FeedItem.search do
      with :hub_feed_ids, id
      order_by :date_published
      paginate per_page: limit
    end
    FeedItem.where(id: search.hits.map(&:primary_key))
            .order('date_published DESC, last_updated DESC')
  rescue Exception => e
    logger.warn(e.inspect)
    []
  end

  # Around 15 (by default) of the latest tags. If tags appear more than once
  # in the latest items, the limit will be off.
  # This is a tradeoff for performance sake.
  def latest_tags(limit = 15)
    # TODO: convert .find to .where and handle the include parameter
    tags = ActsAsTaggableOn::Tagging.find(
      :all,
      include: [:tag],
      conditions: {
        taggable_type: 'FeedItem',
        taggable_id: latest_feed_items.collect(&:id),
        context: hub.tagging_key.to_s
      },
      limit: limit
    ).collect(&:tag).uniq
    return tags
  rescue Exception => e
    logger.warn(e.inspect)
    return []
  end

  def self.title
    'Feed'
  end

  def by_most_recent_tagging
    if feed_items.any?
      feed_items.first.date_published
    else
      feed.updated_at
    end
  end
  
  def self.by_feed_items_count
    includes(:feed_items).sort_by{ |i| i.feed_items.size }
  end

end
