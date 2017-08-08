# frozen_string_literal: true

module FeedItems
  # Determine which users should receive a notification email about changes to a feed item
  class CreateChangeNotification < ActiveInteraction::Base
    object :current_user, class: User
    object :hub
    object :feed_item
    hash :changes, strip: false

    def execute
      users_to_notify = compose(
        FeedItems::LocateUsersToNotify,
        current_user: current_user,
        feed_item: feed_item,
        hub: hub
      )

      return if users_to_notify.blank?

      FeedItems::NotificationsMailer.feed_item_change_notification(
        changes: changes,
        current_user: current_user,
        hub: hub,
        modified_item: feed_item,
        users_to_notify: users_to_notify
      ).deliver_later
    end
  end
end
