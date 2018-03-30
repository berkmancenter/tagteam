# frozen_string_literal: true

module TaggingNotifications
  # Determine which users should receive a notification email about a tagging change affecting a single item
  class CreateNotification < ActiveInteraction::Base
    object :current_user, class: User
    object :hub
    object :feed_item
    hash :changes, strip: false

    def execute
      return if users_to_notify.blank? || tag_exist?

      TaggingNotifications::NotificationsMailer.tagging_change_notification(
        hub,
        feed_item,
        users_to_notify,
        current_user,
        changes
      ).deliver_later
    end

    private

    def tag_exist?
      unique_tag_filters.include?(changes['tags_added'][0])
    end

    def unique_tag_filters
      feed_item.tag_filters.map(&:tag).map(&:name).uniq
    end

    def users_to_notify
      compose(
        FeedItems::LocateUsersToNotify,
        current_user: current_user,
        feed_item: feed_item,
        hub: hub
      )
    end
  end
end
