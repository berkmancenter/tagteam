# frozen_string_literal: true

module FeedItems
  # Create change notifications for the affected items
  class SendChangeNotificationJob < ApplicationJob
    queue_as :default

    def perform(hub:, feed_item:, changes:, current_user:)
      return unless hub.allow_taggers_to_sign_up_for_notifications?

      FeedItems::CreateChangeNotification.run!(
        current_user: current_user,
        hub: hub,
        feed_item: feed_item,
        changes: changes
      )
    end
  end
end
