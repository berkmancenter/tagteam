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

      User.find(taggings.pluck(:tagger_id))
    end
  end
end
