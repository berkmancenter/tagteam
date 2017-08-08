# frozen_string_literal: true

module TaggingNotifications
  # Create tagging notifications for the affected items
  class SendNotificationJob < ApplicationJob
    queue_as :default

    def perform(scope, hub, current_user, changes)
      items_to_process =
        if scope.is_a?(TagFilter)
          scope.items_to_modify
        elsif scope.is_a?(FeedItem)
          [scope]
        end

      items_to_process.each do |modified_item|
        TaggingNotifications::CreateNotification.run!(current_user: current_user, hub: hub, feed_item: modified_item, changes: changes)
      end
    end
  end
end
