class Feed < ActiveRecord::Base

  # Needs to run early to populate the title off the RSS feed.
  validate :feed_url do
    if self.feed_url.blank? || ! self.feed_url.match(/https?:\/\/.+/i)
      self.errors.add(:feed_url, "doesn't look like a url")
      return false
    end
    rss_feed = test_single_feed(self)
    return false unless rss_feed
  end

  include FeedUtilities
  include AuthUtilities
  include ModelExtensions
  acts_as_authorization_object

  after_create :save_feed_items_on_create

	attr_accessible :feed_url, :title, :description
	attr_accessor :raw_feed

	has_many :hub_feeds, :dependent => :destroy
  has_many :feed_retrievals, :order => :created_at, :dependent => :destroy
  has_and_belongs_to_many :feed_items, :order => 'date_published desc'

  searchable do
    text :title, :description, :link, :guid, :rights, :authors, :feed_url, :generator

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

  def items
    self.feed_items
  end
  
  def save_feed_items_on_create
    fr = FeedRetrieval.new(:feed_id => self.id)
    #We wouldn't have gotten here if the feed weren't valid on create.
    fr.success = true
    fr.status_code = '200'
    fr.save
    
    self.raw_feed.items.each do|item|
      fi = FeedItem.find_or_initialize_by_url(:url => item.link)
      logger.warn("Raw Item: " + item.inspect)
      if fi.new_record?
        # Instantiate only for new records.
        fi.title = item.title
        fi.guid = item.guid
        fi.authors = item.author
        fi.contributors = item.contributor

        fi.description = item.summary
        fi.content = item.content
        fi.rights = item.rights
        fi.date_published = ((item.published.blank?) ? item.updated.to_datetime : item.published.to_datetime)
        fi.last_updated = item.updated.to_datetime
      end

      fi.feed_retrieval_id = fr.id
      fi.feeds << self unless fi.feeds.include?(self)

      # Merge tags. . .
      fi.tags = item.categories

      logger.warn("Feed item: #{fi.inspect}")
      if fi.valid?
        fi.save
      else
        logger.warn("Feed item errors: #{fi.errors.inspect}")
      end
    end
  end

  def to_s
    "#{title}"
  end

  alias :display_title :to_s

  def mini_icon
    %q|<span class="ui-silk inline ui-silk-feed"></span>|
  end
end
