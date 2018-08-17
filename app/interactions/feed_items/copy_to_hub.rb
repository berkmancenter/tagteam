# frozen_string_literal: true

module FeedItems
  class CopyToHub < ActiveInteraction::Base
    object :feed_item
    object :hub
    object :current_user, class: User

    def execute
      feed_item.feeds << current_user.get_default_bookmarking_bookmark_collection_for(hub.id)
      feed_item.save!
    end
  end
end
