class FeedItemTagRenderer
  @queue = :feed_items

  def self.perform(feed_item_id)
    fi = FeedItem.find(feed_item_id)
    fi.update_filtered_tags
    Sunspot.commit
  end
end
