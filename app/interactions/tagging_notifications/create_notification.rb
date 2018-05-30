# frozen_string_literal: true

module TaggingNotifications
  # Determine which users should receive a notification email about a tagging change affecting a single item
  # Triggered only when a new bookmarklet is created
  class CreateNotification < ActiveInteraction::Base
    object :current_user, class: User
    object :hub
    object :feed_item
    hash :changes, strip: false

    def execute
      return if tag_exist?

      TaggingNotifications::NotificationsMailer.tagging_change_notification(
        hub,
        feed_item,
        [current_user],
        current_user,
        changes
      ).deliver_later
    end

    private

    def tag_exist?
      feed_item.tag_filters.map(&:tag).map(&:name).uniq.include?(changes['tags_added'][0])
    end
  end
end
