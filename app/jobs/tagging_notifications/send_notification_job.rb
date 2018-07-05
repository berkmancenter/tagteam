# frozen_string_literal: true

module TaggingNotifications
  # Create tagging notifications for the affected items
  class SendNotificationJob < ApplicationJob
    queue_as :default

    def perform(hub, feed_items, tag_filters, updated_by_user, changes)
      # No tag filters means that all tag filters applied to the single feed item need to be found
      notifications = {}
      if tag_filters.empty? # for feed items that were just created
        feed_item = feed_items.first
        notifications[updated_by_user] = feed_items
        DeactivatedTagging.where(taggable_id: feed_item.id, deactivator_type: 'TagFilter').map(&:deactivator).uniq.each do |deactivator|
          if deactivator.is_a?(DeleteTagFilter)
            changes[:tags_deleted] ||= []
            changes[:tags_deleted] << deactivator.tag.name
          elsif deactivator.is_a?(ModifyTagFilter)
            changes[:tags_modified] ||= []
            changes[:tags_modified] << [deactivator.tag.name, deactivator.new_tag.name]
          end
        end
        return if changes.keys.empty?
      else
        feed_items.each do |feed_item|
          feed_item.hub_feeds.each do |hub_feed|
            hub_feed.owners.each do |owner|
              next if owner == updated_by_user
              notifications[owner] ||= []
              notifications[owner] << feed_item
            end
          end
        end
      end

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
