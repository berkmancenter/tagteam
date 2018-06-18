# frozen_string_literal: true

module TaggingNotifications
  # Create tagging notifications for the affected items
  class SendNotificationJob < ApplicationJob
    queue_as :default

    def perform(scope, hub, current_user, changes)
      affected_items = feed_items(scope)

      return if affected_items.length.zero?

      if scope.is_a?(FeedItem) || scope.scope.is_a?(FeedItem) || affected_items.length == 1
        TaggingNotifications::CreateNotification.run!(
          changes: changes,
          current_user: current_user,
          feed_item: affected_items.first,
          hub: hub
        )
      elsif scope.scope.is_a?(TagFilter)
        # Nothing to be done here, although this is called from a couple of places
      end
    end

    private

    def feed_items(scope)
      return [scope] if scope.is_a?(FeedItem)

      scope.items_to_modify
    end
  end
end
