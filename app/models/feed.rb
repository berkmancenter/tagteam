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

	attr_accessible :feed_url, :title, :description
	attr_accessor :raw_feed
	has_and_belongs_to_many :hub_feeds
  has_many :feed_retrievals
  has_many :feed_items
  
  validates_uniqueness_of :feed_url


end
