class ReindexFeedItemsAfterHubFeedDestroyed
  @queue = :feed_items_reindexer

  def self.display_name
    'Reindexing feed items in bulk after a hub feed was removed'
  end

  def self.perform(feed_item_ids = [], tagging_key)

    ActsAsTaggableOn::Tagging.includes([:tag]).destroy_all(:context => tagging_key, :taggable_type => 'FeedItem', :taggable_id => feed_item_ids)

    FeedItem.includes({:taggings => [:tag],:feeds => {:hub_feeds => [:hub]}}).where(:id => feed_item_ids).each do |fi|
      fi.index
    end

    Resque.enqueue(ReindexTags)

  end

end
