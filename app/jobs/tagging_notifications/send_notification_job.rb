# frozen_string_literal: true

module TaggingNotifications
  # Create tagging notifications for the affected items
  class SendNotificationJob < ApplicationJob
    queue_as :default

    def perform(hub, feed_items, tag_filters, updated_by_user, changes, recipients = :owners)
      return unless hub.notify_taggers?
      return unless changes.present? && changes.any?

      notifications = {}
      # Notifications are either going to the owners of the feed items (skipping the updater)
      # or they are going to the updater
      if recipients == :owners
        feed_items.each do |feed_item|
          feed_item.hub_feeds.each do |hub_feed|
            hub_feed.owners.each do |owner|
              next if owner == updated_by_user
              notifications[owner] ||= []
              notifications[owner] << feed_item
            end
          end
        end
      elsif recipients == :updater
        notifications[updated_by_user] = feed_items
      end

      # Send notifications only if notifications are enabled for hub
      notifications.each do |owner, feed_items|
        if owner.notifications_for_hub?(hub)
          TaggingNotifications::NotificationsMailer.tagging_change_notification(
            hub,
            feed_items,
            owner,
            updated_by_user,
            changes
          ).deliver
        end
      end
    end
  end
end
