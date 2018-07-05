# frozen_string_literal: true
module TaggingNotifications
  class ApplyTagFiltersWithNotification < ApplicationJob
    queue_as :default

    # This is a combined method because you can't async them, IE, you need to have apply tag filters
    # finish before send notification job starts to identify tag filter data

    def perform(item_created, hub, updated_by_user, changes)
      if item_created.is_a?(FeedItem)
        ::ApplyTagFilters.new.perform(hub.all_tag_filters.map(&:id), [item_created.id], true)

        return unless hub.notify_taggers?

        SendNotificationJob.new.perform(hub, [item_created], [], updated_by_user, {})
      elsif item_created.is_a?(TagFilter)
        ::ApplyTagFilters.new.perform([item_created.id], [], false)

        return unless hub.notify_taggers?

        SendNotificationJob.new.perform(hub, item_created.filtered_feed_items, [item_created], updated_by_user, changes)
      end
    end
  end
end
