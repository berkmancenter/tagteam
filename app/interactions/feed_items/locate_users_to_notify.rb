# frozen_string_literal: true

module FeedItems
  # Return a collection of users to be notified of tagging changes to a feed item in a given hub
  class LocateUsersToNotify < ActiveInteraction::Base
    object :feed_item
    object :hub
    object :current_user, class: User

    def execute
      users_to_notify = []

      users_to_notify.concat(
        compose(FeedItems::LocateTagFilterUsers, feed_item: feed_item)
      )

      users_to_notify.concat(
        compose(FeedItems::LocateTaggingUsersByHub, feed_item: feed_item, hub: hub)
      )

      users_to_notify.uniq.delete(current_user)

      # remove users who don't have modification notifications enabled
      users_to_notify.select do |user|
        user.hub_user_notifications.find_by(hub: hub).try(:notify_about_modifications?)
      end
    end
  end
end
