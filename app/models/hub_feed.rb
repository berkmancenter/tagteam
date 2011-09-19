class HubFeed < ActiveRecord::Base
  include ModelExtensions
  include AuthUtilities

  acts_as_authorization_object
  belongs_to :hub
  belongs_to :feed
#  after_create :auto_create_republished_feed
#  before_destroy :auto_delete_republished_feed
  validates_uniqueness_of :feed_id, :scope => :hub_id

#  after_update do
#    logger.warn('reindexing everything')
#    reindex_relevant_items
#  end
  
  after_create do
    auto_create_republished_feed
    reindex_items_of_concern
  end

  after_destroy do
    auto_delete_republished_feed
    reindex_items_of_concern
  end

  def display_title
    (self.title.blank?) ? self.feed.title : self.title
  end
  alias :to_s :display_title
  
  def display_description
    (self.description.blank?) ? self.feed.description : self.description
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

  def get_completely_dependent_republished_feeds
    # So. . . we need to find republished feeds that have this feed as a single input source and that belong to this hub.
    # We can do a bunch of tortured ruby, or just run the sql directly.
    rps = RepublishedFeed.connection.execute('select republished_feeds.id from 
        republished_feeds, input_sources 
        where input_sources.republished_feed_id = republished_feeds.id 
        and republished_feeds.hub_id = ' + self.connection.quote(self.hub_id) +  
        ' and input_sources.item_source_type = ' + self.connection.quote('Feed') + 
        ' and input_sources.item_source_id = ' + self.connection.quote(self.feed_id)
    )
  end

  private

  def auto_delete_republished_feed
    rps = RepublishedFeed.find(:all, :conditions => {:id => self.get_completely_dependent_republished_feeds.collect{|r| r['id']}})
    rps.each do|rp|
      if rp.input_sources.length == 1
        rp.destroy
      else
        # More than one input source. Clear it out anyway.
        InputSource.destroy_all(:republished_feed_id => rp.id, :item_source_type => 'Feed', :item_source_id => self.feed.id)
      end
    end
  end

  def auto_create_republished_feed

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
      logger.warn("Couldn't auto create republished feed: " + rf.errors.inspect)
    end

    input_source = InputSource.new(
      :republished_feed_id => rf.id, 
      :item_source => self.feed,
      :effect => 'add',
      :position => 1,
      :limit => 50
    )

    if input_source.valid?
      input_source.save
    else
      logger.warn("Couldn't auto create input source: " + input_source.errors.inspect)
    end
  end

  def reindex_items_of_concern
    logger.warn('reindexing everything')
    self.feed.solr_index
    self.feed.feed_items.collect{|fi| fi.solr_index}
    self.feed.feed_item_tags{|ft| ft.solr_index}
  end

end
