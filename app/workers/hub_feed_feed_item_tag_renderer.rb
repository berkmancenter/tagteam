class HubFeedFeedItemTagRenderer
  @queue = :hub_feed

  def self.perform(hub_feed_id, tag_id = nil)
    hub_feed = HubFeed.find(hub_feed_id)
    feed_items = []
    if tag_id.nil?
      # Act on all items
      feed_items = FeedItem.includes(:feeds).where({'feeds.id' => hub_feed.feed_id})
    else
      # act only on items with the tag of interest.
      feed_items = FeedItem.includes(:feeds,:taggings).where({'feeds.id' => hub_feed.feed_id, 'taggings.tag_id' => tag_id, 'taggings.context' => 'tags'})
    end

    feed_items.each do |fi|
      fi.render_filtered_tags_for_hub(hub_feed.hub)
    end
  end

end
