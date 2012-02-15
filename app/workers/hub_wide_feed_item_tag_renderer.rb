class HubWideFeedItemTagRenderer
  @queue = :hub_wide

  def self.perform(hub_id, tag_id = nil)
    # Here is where we'll update all the items affected by this change in this feed.
    # if hub_tag_filter_id is nil, then this was a deleted filter and we should change our behavior accordingly.

    hub = Hub.find(hub_id)
    feed_items = []
    if tag_id.nil?
      # Act on all items
      feed_items = FeedItem.includes(:feeds).where({'feeds.id' => hub.feeds.collect{|f| f.id}})
    else
      # act only on items with the tag of interest.
      feed_items = FeedItem.includes(:feeds,:taggings).where({'feeds.id' => hub.feeds.collect{|f| f.id}, 'taggings.tag_id' => tag_id, 'taggings.context' => 'tags'})
    end

    ac = ActionController::Base.new

    feed_items.each do |fi|
      fi.render_filtered_tags_for_hub(hub)
      fi.save

      key = "feed-item-tag-list-#{hub.id}-#{fi.id}"
      # puts "Expiring #{key}"
      ac.expire_fragment(key)
    end
#    Sunspot.commit
  end

end
