# frozen_string_literal: true

class HubFeedObserver < ActiveRecord::Observer
  def after_create(hub_feed)
    return if hub_feed.skip_global_tag_copy
    hub_feed.copy_global_tags_to_hubs
    Sunspot.index hub_feed.feed_items
  end
end
