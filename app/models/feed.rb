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

	has_many :hub_feeds
  has_many :feed_retrievals, :order => :created_at
  has_many :feed_items
  
  validates_uniqueness_of :feed_url
  
  def save_feed_items_on_create
    fr = FeedRetrieval.new(:feed_id => self.id)

    #We wouldn't have gotten here if the feed weren't valid on create.
    fr.success = true
    fr.status_code = '200'
    fr.save
    
    self.raw_feed.items.each do|item|
       fi = FeedItem.new(
        :feed_id => self.id, 
        :feed_retrieval_id => fr.id, 
        :title => item.title,
        :url => item.url,
        :author => (item.authors.blank?) ? '' : item.authors.join(','),
        :description => item.description,
        :content => item.content,
        :copyright => item.copyright,
        :date_published => item.date_published
      )
      fi.tags = item.categories
      fi.save
    end

  end


end
