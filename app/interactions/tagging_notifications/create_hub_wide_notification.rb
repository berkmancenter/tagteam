# frozen_string_literal: true

module TaggingNotifications
  # Determine which users should receive a notification email about a hub-wide tagging change
  class CreateHubWideNotification < ActiveInteraction::Base
    hash :changes, strip: false
    object :current_user, class: User

    array :feed_items do
      object class: FeedItem
    end

    object :hub

    def execute
      users_to_notify = feed_item_taggers(feed_items, hub) + tag_filter_taggers(hub)

      users_to_notify.uniq!

      users_to_notify.delete(current_user)

      return if users_to_notify.blank?

      TaggingNotifications::NotificationsMailer.hub_wide_tagging_change(
        changes: changes,
        current_user: current_user,
        feed_item_count: feed_items.length,
        hub: hub,
        users_to_notify: users_to_notify
      ).deliver_later
    end

    private

    # return users who tagged a feed item directly or via single-item tag filter
    def feed_item_taggers(feed_items, hub)
      feed_items.map do |feed_item|
        compose(FeedItems::LocateTaggingUsersByHub, feed_item: feed_item, hub: hub) +
          compose(FeedItems::LocateTagFilterUsers, feed_item: feed_item)
      end.flatten.uniq
    end

    # return users who created hub-wide tag filters
    def tag_filter_taggers(hub)
      TagFilter.where(scope: hub).map(&:users).flatten.uniq
    end
  end
end
