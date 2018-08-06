# frozen_string_literal: true

module FeedItems
  # Return a collection of users of tag filters applied to the feed item
  class MoveToHub < ActiveInteraction::Base
    object :feed_item
    object :from_hub_feed, class: HubFeed
    object :to_hub, class: Hub
    object :current_user, class: User

    def execute
      feed_item.feeds -= [from_hub_feed.feed]
      feed_item.feeds << current_user.get_default_bookmarking_bookmark_collection_for(to_hub.id)
      feed_item.save!
    end
  end
end
