class HubFeed < ActiveRecord::Base
  include ModelExtensions
  before_validation do
    auto_sanitize_html(:description)
  end
  include AuthUtilities

  acts_as_authorization_object
  belongs_to :hub
  belongs_to :feed
  has_many :feed_items, :through => :feed
  has_many :hub_feed_tag_filters, :dependent => :destroy, :order => :position
  validates_uniqueness_of :feed_id, :scope => :hub_id
  validates_presence_of :feed_id, :hub_id

  scope :stacks, lambda { joins(:feed).where('feeds.bookmarking_feed' => true) }
  scope :rss, lambda { joins(:feed).where('feeds.bookmarking_feed' => false) }

  scope :need_updating, lambda { joins(:feed).where(['feeds.next_scheduled_retrieval <= ? and bookmarking_feed is false', Time.now]) }

  attr_accessible :title, :description
  
  after_create do
    logger.warn('After create is firing')
    reindex_items_of_concern
    Resque.enqueue(HubFeedFeedItemTagRenderer, self.id)
  end

  after_destroy do
    reindex_items_of_concern

    ActsAsTaggableOn::Tagging.destroy_all(:context => self.hub.tagging_key.to_s, :taggable_type => 'FeedItem', :taggable_id => self.feed.feed_items.collect{|fi| fi.id})
    Resque.enqueue(ReindexTags)
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

  def self.per_page
    25
  end

  def self.descriptive_name
    'Feed'
  end

  def display_title
    (self.title.blank?) ? self.feed.title : self.title
  end
  alias :to_s :display_title
  
  def display_description
    (self.description.blank?) ? self.feed.description : self.description
  end

  def link
    self.feed.link
  end

  def guid
    self.feed.guid
  end

  def rights
    self.feed.rights
  end

  def authors
    self.feed.authors
  end

  def feed_url
    self.feed.feed_url
  end
  
  def generator
    self.feed.generator
  end

  def last_updated
    self.feed.last_updated
  end

  def flavor
    self.feed.flavor
  end

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

  def feed_item_count
    res = self.connection.execute('select count(*) from feed_items_feeds where feed_id = ' + self.connection.quote(self.feed_id))
    res.first['count']
  rescue
    0
  end

  def latest_feed_items(limit = 15)
    self.feed.feed_items.limit(limit)
  rescue Exception => e
    logger.warn(e.inspect)
    []
  end

  def latest_tags(limit = 15)
    self.latest_feed_items.includes(:taggings).collect{|fi| fi.taggings.reject{|tg| tg.context != self.hub.tagging_key.to_s}.collect{|tg| tg.tag} }.flatten.uniq[0,limit]
  rescue Exception => e
    logger.warn(e.inspect)
    return []
  end

  private

  def reindex_items_of_concern
    logger.warn('reindexing everything')
    self.feed.solr_index
    self.feed.feed_items.collect{|fi| fi.solr_index}
  end

end
