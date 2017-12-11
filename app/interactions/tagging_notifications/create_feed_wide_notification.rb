# frozen_string_literal: true

module TaggingNotifications
  # Determine which users should receive a notification email about a feed-wide tagging change
  class CreateFeedWideNotification < ActiveInteraction::Base
    hash :changes, strip: false
    object :current_user, class: User

    array :feed_items do
      object class: FeedItem
    end

    object :hub_feed

    def execute
      users_to_notify = feed_item_taggers(feed_items, hub_feed.hub) + tag_filter_taggers(hub_feed)

      users_to_notify.uniq!

      users_to_notify.delete(current_user)

      return if users_to_notify.blank?

      TaggingNotifications::NotificationsMailer.feed_wide_tagging_change(
        changes: changes,
        current_user: current_user,
        feed_item_count: feed_items.length,
        hub_feed: hub_feed,
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

    # return users who created feed-wide tag filters
    def tag_filter_taggers(hub_feed)
      TagFilter.where(scope: hub_feed).map(&:users).flatten.uniq
    end
  end
end
