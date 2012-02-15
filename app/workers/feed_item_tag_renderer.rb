class FeedItemTagRenderer
  @queue = :feed_items

  def self.perform(feed_item_id)
    fi = FeedItem.find(feed_item_id)
    fi.update_filtered_tags

    ac = ActionController::Base.new
    fi.hubs.each do|h|
      key = "feed-item-tag-list-#{h.id}-#{fi.id}"
      # puts "Expiring #{key}"
      ac.expire_fragment(key)
    end
   
    #Sunspot.commit
  end
end
