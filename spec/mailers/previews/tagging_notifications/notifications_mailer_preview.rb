# frozen_string_literal: true

module TaggingNotifications
  class NotificationsMailerPreview < ActionMailer::Preview
    def feed_wide_tagging_change
      changes = { tags_added: ['thing1'] }
      current_user = User.first
      feed_item_count = 50
      hub_feed = HubFeed.first
      users_to_notify = [current_user]

      NotificationsMailer.feed_wide_tagging_change(
        changes: changes,
        current_user: current_user,
        feed_item_count: feed_item_count,
        hub_feed: hub_feed,
        users_to_notify: users_to_notify
      )
    end

    def hub_wide_tagging_change
      changes = { tags_added: ['thing1'] }
      current_user = User.first
      feed_item_count = 50
      hub = Hub.first
      users_to_notify = [current_user]

      NotificationsMailer.hub_wide_tagging_change(
        changes: changes,
        current_user: current_user,
        feed_item_count: feed_item_count,
        hub: hub,
        users_to_notify: users_to_notify
      )
    end

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
