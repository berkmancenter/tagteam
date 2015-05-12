# A HubFeed links a Hub with a Feed. A Hub has many HubFeeds.
#
# A HubFeed inherits most its metadata from its parent Feed, but a Hub owner can override the title and description by editing the HubFeed.
# 
# Most validations are contained in the ModelExtensions mixin.
#
class HubFeed < ActiveRecord::Base
  include ModelExtensions
  before_validation do
    auto_sanitize_html(:description)
  end
  include AuthUtilities

  acts_as_authorization_object
  acts_as_api do|c|
    c.allow_jsonp_callback = true
  end
  belongs_to :hub
  belongs_to :feed
  has_many :feed_items, :through => :feed
  has_many :hub_feed_tag_filters, :dependent => :destroy, :order => 'updated_at desc'
  validates_uniqueness_of :feed_id, :scope => :hub_id
  validates_presence_of :feed_id, :hub_id

  scope :bookmark_collections, lambda { joins(:feed).where('feeds.bookmarking_feed' => true) }
  scope :rss, lambda { joins(:feed).where('feeds.bookmarking_feed' => false) }

  scope :need_updating, lambda { joins(:feed).where(['feeds.next_scheduled_retrieval <= ? and bookmarking_feed is false', Time.now]) }

  attr_accessible :title, :description

  api_accessible :default do|t|
    t.add :id
    t.add :display_title, :as => :title
    t.add :display_description, :as => :description
    t.add :link
    t.add :hub
    t.add :feed
  end
  
  # If a new HubFeed gets created, we need to ensure that the tag facets on the feed items it contains (whether those items exist already in TagTeam or not) are calculated.
  after_create do
    self.feed.solr_index
    Sidekiq::Client.enqueue(HubFeedFeedItemTagRenderer, self.id)
  end

  after_destroy do
    # Clean up any input_sources that might've been using the feed this points to.
    InputSource.joins(:republished_feed).where('republished_feeds.hub_id' => self.hub_id).where(:item_source_type => 'Feed', :item_source_id => self.feed_id).destroy_all

    # Clean up feed_item input sources 
    InputSource.joins(:republished_feed).where('republished_feeds.hub_id' => self.hub_id).where(:item_source_type => 'FeedItem', :item_source_id => self.feed.feed_items.collect{|f| f.id}).destroy_all

    self.feed.solr_index
    feed_items_of_concern = self.feed.feed_items.collect{|fi| fi.id}
    tagging_key = self.hub.tagging_key.to_s
    Sidekiq::Client.enqueue(ReindexFeedItemsAfterHubFeedDestroyed, feed_items_of_concern, tagging_key)
    Sidekiq::Client.enqueue(ReindexFeedRetrievals, self.feed.id)
  end

  def hub_ids
    [self.hub_id]
  end

  searchable(:include => [:hub]) do
    text :display_title, :display_description, :link, :guid, :rights, :authors, :feed_url, :generator
    integer :hub_ids, :multiple => true

    integer :feed_item_ids, :multiple => true

    string :title
    string :guid
    time :last_updated
    string :rights
    string :authors
    string :feed_url
    string :link
    string :generator
    string :flavor
    string :language
  end

  def self.title
    'Feed'
  end

  def display_title
    (self.title.blank?) ? self.feed.title : self.title
  end
  alias :to_s :display_title
  
  def display_description
    (self.description.blank?) ? self.feed.description : self.description
  end

  # Inherited from this HubFeed's feed.
  def link
    self.feed.link
  end

  # Inherited from this HubFeed's feed.
  def guid
    self.feed.guid
  end

  # Inherited from this HubFeed's feed.
  def rights
    self.feed.rights
  end

  # Inherited from this HubFeed's feed.
  def authors
    self.feed.authors
  end

  # Inherited from this HubFeed's feed.
  def feed_url
    self.feed.feed_url
  end
  
  # Inherited from this HubFeed's feed.
  def generator
    self.feed.generator
  end

  # Inherited from this HubFeed's feed.
  def last_updated
    self.feed.last_updated
  end

  # Inherited from this HubFeed's feed.
  def flavor
    self.feed.flavor
  end

  # Inherited from this HubFeed's feed.
  def language
    self.feed.language
  end

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
      with :hub_feed_ids, self.id
      order_by :date_published
      paginate per_page: limit
    end
    FeedItem.where(id: search.hits.map(&:primary_key)).order('date_published DESC, last_updated DESC')
  rescue Exception => e
    logger.warn(e.inspect)
    []
  end

  # Around 15 (by default) of the latest tags. If tags appear more than once in the latest items, the limit will be off. This is a tradeoff for performance sake.
  def latest_tags(limit = 15)
    tags = ActsAsTaggableOn::Tagging.find(
      :all,
      include: [:tag],
      conditions: {
        taggable_type: 'FeedItem',
        taggable_id: self.latest_feed_items.collect(&:id),
        context: self.hub.tagging_key.to_s
      },
      limit: limit).collect(&:tag).uniq
    return tags
  rescue Exception => e
    logger.warn(e.inspect)
    return []
  end

end
