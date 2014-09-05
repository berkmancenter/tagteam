class HubFeedFeedItemTagRenderer
  @queue = :renderer

  def self.display_name
    'Updating tag facets for an entire feed'
  end

  def self.perform(hub_feed_id, tag_id = nil)
    hub_feed = HubFeed.find(hub_feed_id)

    feed_items = []
    if tag_id.nil?
      # Act on all items
      feed_items = FeedItem.includes(:feeds,:taggings).where({'feeds.id' => hub_feed.feed_id})
    else
      # act only on items with the tag of interest.
      feed_items = FeedItem.includes(:feeds,:taggings).where({'feeds.id' => hub_feed.feed_id, 'taggings.tag_id' => tag_id, 'taggings.context' => 'tags'})
    end

    ac = ActionController::Base.new

    # Re-render tags.
    feed_items.each do |fi|
      fi.render_filtered_tags_for_hub(hub_feed.hub)
      fi.skip_tag_indexing_after_save = true
      fi.save
    end

    #batch reindex tags.
    ActsAsTaggableOn::Tag.includes(:taggings).where('taggings.taggable_type' => 'FeedItem', 'taggings.taggable_id' => feed_items.collect{|fi| fi.id}).solr_index(:batch_size => 500, :batch_commit => false)

    #batch expire caches.
    feed_items.each do|fi|
      key = "feed-item-tag-list-#{hub_feed.hub.id}-#{fi.id}"
      ac.expire_fragment(key)
    end
  end

end
