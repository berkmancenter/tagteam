class Feed < ActiveRecord::Base
  validate :feed_url do
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

  include FeedUtilities
  include AuthUtilities
  include ModelExtensions
  acts_as_authorization_object

  @dirty_feed_items = []

  before_create :set_next_scheduled_retrieval_on_create
  after_create :save_feed_items_on_create

	attr_accessible :feed_url, :title, :description
	attr_accessor :raw_feed, :status_code, :dirty, :changelog, :dirty_feed_items

	has_many :hub_feeds, :dependent => :destroy
  has_many :hubs, :through => :hub_feeds
  has_many :feed_retrievals, :order => 'created_at desc', :dependent => :destroy
  has_and_belongs_to_many :feed_items, :order => 'date_published desc'

  def self.descriptive_name
    'Feed'
  end

  searchable(:include => [:hubs, :hub_feeds]) do
    text :title, :description, :link, :guid, :rights, :authors, :feed_url, :generator
    integer :hub_ids, :multiple => true

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
  
  validates_uniqueness_of :feed_url

  scope :need_updating, lambda { where(['next_scheduled_retrieval <= ?', Time.now]) }

  def set_next_scheduled_retrieval

    feed_last_changed_at = self.items_changed_at 
    feed_changed_this_long_ago = Time.now - feed_last_changed_at
    max_next_scheduled_retrieval_time = Time.now + MAXIMUM_FEED_SPIDER_INTERVAL 

    if feed_changed_this_long_ago > SPIDER_UPDATE_DECAY
      logger.warn('Feed looks old, pushing out next spidering event by SPIDER_DECAY_INTERVAL')
      last_interval_was = self.next_scheduled_retrieval - self.updated_at 
      next_spider_time = Time.now + last_interval_was + SPIDER_DECAY_INTERVAL
      self.next_scheduled_retrieval = (next_spider_time > max_next_scheduled_retrieval_time) ? max_next_scheduled_retrieval_time : next_spider_time
    else
      #Changed in the last two hours.
      logger.warn('Feed JUST changed.')
      self.next_scheduled_retrieval = Time.now + MINIMUM_FEED_SPIDER_INTERVAL
    end
  end

  def update_feed
    self.dirty = false
    self.changelog = {}
    parsed_feed = fetch_and_parse_feed(self)
    if ! parsed_feed 
      logger.warn('we could not update this feed: ' + self.inspect)
      FeedRetrieval.create(:feed_id => self.id, :success => false, :status_code => self.status_code) 
      self.set_next_scheduled_retrieval
      self.save
      return false
    end
    fr = FeedRetrieval.new(:feed_id => self.id)
    fr.success = true
    fr.status_code = '200'
    fr.save
    self.raw_feed.items.each do|item|
      self.update_feed_item(item,fr)
    end
    self.set_next_scheduled_retrieval
    fr.changelog = self.changelog.to_yaml
    fr.save

    if self.dirty == true
      logger.warn('dirty Feed and/or feed items have changed.')
      self.items_changed_at = Time.now
    end
    self.save
  end

  def update_feed_item(item, fr)
    fi = FeedItem.find_or_initialize_by_url(:url => item.link)
    item_changelog = {}

    fi.title = item.title
    fi.description = item.summary

    if fi.new_record?
      # Instantiate only for new records.
      fi.guid = item.guid
      fi.authors = item.author
      fi.contributors = item.contributor

      fi.description = item.summary
      fi.content = item.content
      fi.rights = item.rights
      fi.date_published = ((item.published.blank?) ? item.updated.to_datetime : item.published.to_datetime)
      fi.last_updated = item.updated.to_datetime
      logger.warn('dirty because there is a new feed_item')
      item_changelog[:new_record] = true
      self.dirty = true
    end
    fi.feed_retrievals << fr
    fi.feeds << self unless fi.feeds.include?(self)
    # Merge tags. . .
    pre_update_tags = fi.tag_list.dup.sort
    # Autotruncate tags to be no longer than 255 characters. This would be better done at the model level.
    fi.tag_list = item.categories.collect{|t| t.downcase[0,255]}.join(',')
    if pre_update_tags != fi.tag_list.sort
      logger.warn('dirty because tags have changed')
      self.dirty = true
      unless fi.new_record?
        # Be sure to update the feed changelog here in case
        # an item only has tag changes.
        item_changelog[:tags] = [pre_update_tags, fi.tag_list]
        self.changelog[fi.id] = item_changelog
      end
    end
    if fi.valid?
      if fi.changed? or fi.new_record?
        # This runs here because we're auto stripping and auto-truncating columns and
        # want the change tracking to be relative to these fixed values.
        logger.warn('dirty because a feed item changed or was created.')
        logger.warn('dirty Changes: ' + fi.changes.inspect)
        unless fi.new_record?
          item_changelog.merge!(fi.changes)
        end
        logger.warn('dirty item_changelog: ' + item_changelog.inspect)
        self.dirty = true
        fi.save
        self.changelog[fi.id] = item_changelog

        # Changed and/or new, so recalculate tag filtering.
        logger.warn('Enqueueing resque jobs')
        Resque.enqueue(FeedItemTagRenderer, fi.id)
      end
    else
      logger.warn("Couldn't auto create feed_item: #{fi.errors.inspect}")
    end
  end

  def items
    # TODO - tweak the include?
    self.feed_items.find(:all, :include => [:taggings, :tags], :order => 'id desc')
  end
  
  def save_feed_items_on_create
    self.dirty = false
    self.changelog = {}
    fr = FeedRetrieval.new(:feed_id => self.id)
    #We wouldn't have gotten here if the feed weren't valid on create.
    fr.success = true
    fr.status_code = '200'
    fr.save
    self.raw_feed.items.each do|item|
      self.update_feed_item(item,fr)
    end
    fr.changelog = self.changelog.to_yaml
    fr.save
  end

  def to_s
    "#{title}"
  end

  alias :display_title :to_s

  def mini_icon
    %q|<span class="ui-silk inline ui-silk-feed"></span>|
  end

  def set_next_scheduled_retrieval_on_create
    # Not going to bother checking to see if it's changed as this is a new feed. Let's assume the best!
    if self.items_changed_at.nil?
      self.items_changed_at = Time.now 
    end
    self.next_scheduled_retrieval = Time.now + MINIMUM_FEED_SPIDER_INTERVAL
  end
end
