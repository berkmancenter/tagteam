class HubFeedObserver < ActiveRecord::Observer
  def after_create(hub_feed)
    return if hub_feed.skip_tag_copy
    copy_feed_tags_to_hub(hub_feed)
  end

  def copy_feed_tags_to_hub(hub_feed)
    hub_feed.feed.feed_items.each do |item|
      item.class.observer_instances.first.copy_tags_to_hubs(item)
    end
  end
end
