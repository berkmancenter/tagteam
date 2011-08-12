class HubFeed < ActiveRecord::Base
  include ModelExtensions

  belongs_to :hub
  belongs_to :feed

  validates_uniqueness_of :feed_id, :scope => :hub_id

  def display_title
    (self.title.blank?) ? self.feed.title : self.title
  end
  
  def display_description
    (self.description.blank?) ? self.feed.description : self.description
  end

  def latest_feed_retrieval
    feed.feed_retrievals.last
  rescue Exception => e
    logger.warn(e.inspect)
    []
  end

  def latest_feed_items
    self.latest_feed_retrieval.feed_items
  rescue Exception => e
    logger.warn(e.inspect)
    []
  end

  def latest_feed_tags
    self.latest_feed_items.collect{|fi| fi.feed_item_tags}.flatten.uniq.compact
  rescue Exception => e
    logger.warn(e.inspect)
    return []
  end

end
