# frozen_string_literal: true

module FeedItems
  # Return a collection of users who have directly tagged a feed item in a hub
  class LocateTaggingUsersByHub < ActiveInteraction::Base
    object :feed_item
    object :hub

    def execute
      taggings = ActsAsTaggableOn::Tagging.where(
        tagger_type: 'User',
        taggable_id: feed_item.id,
        taggable_type: 'FeedItem',
        context: "hub_#{hub.id}"
      )

      taggers = User.find(taggings.pluck(:tagger_id))

      # Remove users that tagged the item, but are not subscribed to the hub
      # anymore
      taggers.select! { |tagger| tagger.subscribed_to_hub?(hub) }

      taggers
    end
  end
end
