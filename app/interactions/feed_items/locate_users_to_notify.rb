# frozen_string_literal: true

module FeedItems
  # Return a collection of users to be notified of changes to a feed item in a given hub
  class LocateUsersToNotify < ActiveInteraction::Base
    object :feed_item
    object :hub
    object :current_user, class: User

    def execute
      users_to_notify = tag_filter_users | tagging_users

      return users_to_notify if users_to_notify.empty?

      users_to_notify.delete(current_user)

      # remove users who don't have modification notifications enabled
      users_to_notify.select { |user| user.notifications_for_hub?(hub) }
    end

    private

    def tag_filter_users
      compose(FeedItems::LocateTagFilterUsers, feed_item: feed_item)
    end

    def tagging_users
      compose(FeedItems::LocateTaggingUsersByHub, feed_item: feed_item, hub: hub)
    end
  end
end
