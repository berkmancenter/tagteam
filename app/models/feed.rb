# A Hub contains many Feeds through the HubFeed class. A Feed belongs to many
# HubFeeds (allowing it to be used in many Hubs) and is unique on the feed_url.
#
# A Feed maps directly to an individual RSS feed, unless it's a bookmark
# collection. A Feed contains many FeedItem objects.
#
# If a Feed is a bookmark collection, it serves only to hold FeedItems added
# via the Bookmarklet. This lets us leverage the rest of the filtering,
# searching, aggregating and other features built into TagTeam. A bookmark
# collection is identified by the "bookmarking_feed" boolean being true. When
# this boolean is true, feed_url validations are bypassed and it will never be
# spidered.
#
#
# Most validations are contained in the ModelExtensions mixin.

class Feed < ActiveRecord::Base
  include FeedUtilities
  include AuthUtilities
  include ModelExtensions

  acts_as_authorization_object
  acts_as_tagger
  acts_as_api do|c|
    c.allow_jsonp_callback = true
  end

  @dirty_feed_items = []

  before_create :set_next_scheduled_retrieval_on_create,
    unless: Proc.new{|rec| rec.is_bookmarking_feed?}
  after_create :save_feed_items_on_create,
    unless: Proc.new{|rec| rec.is_bookmarking_feed?}
  before_destroy :remove_feed_items_feeds

  attr_accessible :feed_url, :title, :description, :bookmarking_feed
  attr_accessor :raw_feed, :status_code, :dirty, :changelog, :dirty_feed_items

  has_many :hub_feeds, dependent: :destroy
  has_many :hubs, through: :hub_feeds
  has_many :feed_retrievals, order: 'created_at desc', dependent: :delete_all
  has_many :input_sources, dependent: :delete_all, as: :item_source
  has_and_belongs_to_many :feed_items, order: 'date_published desc'



  api_accessible :default do|t|
    t.add :authors
    t.add :id
    t.add :title
    t.add :feed_url
    t.add :bookmarking_feed
  end

  api_accessible :bookmarklet_choices do|t|
    t.add :authors
    t.add :id
    t.add :title
  end

  searchable(:include => [:hubs, :hub_feeds]) do
    text :title, :description, :link, :guid, :rights, :authors,
      :feed_url, :generator
    integer :hub_ids, multiple: true

    string :title
    string :guid
    string :rights
    string :authors
    string :feed_url
    string :link
    string :generator
    string :flavor
    string :language
    boolean :bookmarking_feed
    time :last_updated
  end

  validates_uniqueness_of :feed_url,
    unless: Proc.new{ |rec| rec.is_bookmarking_feed? }
  validate :feed_url do
    return if self.is_bookmarking_feed?
    if self.feed_url.blank? || ! self.feed_url.match(/https?:\/\/.+/i)
      self.errors.add(:feed_url, "doesn't look like a url")
      return false
    end
    if self.new_record?
      # Only validate the actual RSS when the feed is created.
      rss_feed = test_single_feed(self)
      return false unless rss_feed
    end
  end

  # TagTeam uses a decaying update interval - the less a Feed changes, the
  # longer we go between spidering up to the maximum_feed_spider_interval (1
  # day by default) setting in the tagteam.rb initializer.
  #
  # Once a feed goes more than spider_update_decay (2 hours by default) from
  # its last change, we increment the next check by an additional
  # spider_decay_interval (1 hour by default).
  #
  # We will reset the decay timer when the Feed changes, and spider it again in
  # the next minimum_feed_spider_interval (15 minutes by default).
  #
  # So - with the default values - if after around of spidering at
  # minimum_feed_spider_interval a feed hasn't changed in 2 hours, we'll check
  # it again in three. If it hasn't changed in three, we'll check it in four
  # - and so on up to a maximum of a day between checks. If the feed changes at
  # any point, we'll start re-spidering it again at
  # minimum_feed_spider_interval, looking for changes and starting the decay
  # cycle over again after 2 hours.
  #
  # This lets us have a good balance ensuring slowly changing feeds get checked
  # while rapidly changing feeds are spidered more quickly. It also helps to
  # catch edits done after an item is published in a timely fashion, it's
  # pretty common for a publisher to revise an item right after making it
  # public.
  def set_next_scheduled_retrieval
    feed_last_changed_at = self.items_changed_at
    feed_changed_this_long_ago = Time.now - feed_last_changed_at
    max_next_scheduled_retrieval_time = Time.now +
      Tagteam::Application.config.maximum_feed_spider_interval

    if feed_changed_this_long_ago > Tagteam::Application.config.spider_update_decay
      logger.warn("Feed #{self.id} looks old, pushing out next spidering " +
                  "event by spider_decay_interval, which is " +
                  Tagteam::Application.config.spider_decay_interval)
      last_interval_was = self.next_scheduled_retrieval - self.updated_at
      next_spider_time = Time.now + last_interval_was +
        Tagteam::Application.config.spider_decay_interval
      self.next_scheduled_retrieval =
        (next_spider_time > max_next_scheduled_retrieval_time) ?
        max_next_scheduled_retrieval_time : next_spider_time
    else
      #Changed in the last two hours.
      logger.warn("Feed #{self.id} JUST changed.")
      self.next_scheduled_retrieval = Time.now +
        Tagteam::Application.config.minimum_feed_spider_interval
    end
  end

  def is_bookmarking_feed?
    self.bookmarking_feed
  end

  # The method called by UpdateFeeds to download and parse new FeedItem
  # content. A FeedRetrieval object documenting this event is created with
  # a changelog of new or changed FeedItem objects that were seen. This may
  # spawn Resque jobs if/when items change or are added. The meat of updating
  # a FeedItem lives in the FeedItem#create_or_update_feed_item method.
  def update_feed
    return if self.bookmarking_feed?

    self.dirty = false
    self.changelog = {}
    parsed_feed = fetch_and_parse_feed(self)
    if ! parsed_feed
      logger.warn("We could not update this Feed #{self.id} : " + self.inspect)
      FeedRetrieval.create(feed_id: self.id, success: false,
                           status_code: self.status_code)
      self.set_next_scheduled_retrieval
      self.save
      return false
    end
    fr = FeedRetrieval.new(feed_id: self.id)
    fr.success = true
    fr.status_code = '200'
    self.raw_feed.items.each do|item|
      FeedItem.create_or_update_feed_item(self,item,fr)
    end
    fr.changelog = self.changelog.to_yaml
    fr.save

    if self.dirty == true
      self.items_changed_at = Time.now
    end
    self.set_next_scheduled_retrieval
    self.save
  end

  # A list of the FeedItem objects contained in this feed - this method is used
  # by the RepublishedFeed system, which expects an InputSource to provide an
  # items method that contains an array of FeedItem objects.
  def items(not_needed)
    # TODO - tweak the include?
    self.feed_items.find(:all, :include => [:taggings, :tags], order: 'id desc')
  end

  # Takes the parse FeedItems and saves them along with a FeedRetrieval when
  # a Feed is created.
  def save_feed_items_on_create
    self.dirty = false
    self.changelog = {}
    fr = FeedRetrieval.new
    fr.feed_id = self.id
    #We wouldn't have gotten here if the feed weren't valid on create.
    fr.success = true
    fr.status_code = '200'
    fr.save
    self.raw_feed.items.each do|item|
      FeedItem.create_or_update_feed_item(self,item,fr)
    end
    fr.changelog = self.changelog.to_yaml
    fr.save
  end

  def to_s
    "#{title}"
  end
  alias :display_title :to_s

  # Used in the RepublishedFeed system to give this Feed an icon in lists.
  def mini_icon
    %q|<span class="ui-silk inline ui-silk-feed"></span>|
  end

  def set_next_scheduled_retrieval_on_create
    # Not going to bother checking to see if it's changed as this is a new
    # feed. Let's assume the best!
    if self.items_changed_at.nil?
      self.items_changed_at = Time.now
    end
    self.next_scheduled_retrieval = Time.now +
      Tagteam::Application.config.minimum_feed_spider_interval
  end

  def self.title
    'Feed'
  end

  private

  def remove_feed_items_feeds
    self.connection.execute("DELETE FROM feed_items_feeds WHERE feed_id = #{id}")
  end
end
