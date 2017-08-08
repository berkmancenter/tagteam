# frozen_string_literal: true

module TaggingNotifications
  class NotificationsMailerPreview < ActionMailer::Preview
    def tagging_change_notification
      hub = Hub.first
      modified_item = hub.feed_items.first
      item_users = [User.first]
      current_user = User.first
      changes = { tags_modified: %w[tag1 tag2] }

      NotificationsMailer.tagging_change_notification(hub, modified_item, item_users, current_user, changes)
    end
  end
end
