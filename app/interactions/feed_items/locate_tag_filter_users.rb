# frozen_string_literal: true

module FeedItems
  # Return a collection of users of tag filters applied to the feed item
  class LocateTagFilterUsers < ActiveInteraction::Base
    object :feed_item

    def execute
      feed_item.tag_filters.map(&:users).flatten.uniq
    end
  end
end
