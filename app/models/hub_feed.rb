class HubFeed < ActiveRecord::Base
  include ModelExtensions

  belongs_to :hub
  belongs_to :feed
  after_create :auto_create_republished_feed
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
    self.feed.feed_items.limit(15)
  rescue Exception => e
    logger.warn(e.inspect)
    []
  end

  def latest_feed_tags
    self.latest_feed_items.includes(:feed_item_tags).collect{|fi| fi.feed_item_tags}.flatten.uniq.compact
  rescue Exception => e
    logger.warn(e.inspect)
    return []
  end

  def auto_create_republished_feed

    logger.warn('Feed info:' + self.feed.inspect)
    rf = RepublishedFeed.new(
      :hub_id => self.hub_id, 
      :title => self.feed.title, 
      :description => self.feed.description,
      :default_sort => 'date_published',
      :mixing_strategy => 'date',
      :limit => 50
    )

    if rf.valid?
      rf.save
    else
      logger.warn(rf.errors.inspect)
    end

    input_source = InputSource.new(
      :republished_feed_id => rf.id, 
      :item_source => self.feed,
      :effect => 'add',
      :position => 1,
      :limit => 50
    )
    input_source.save
  end

end
