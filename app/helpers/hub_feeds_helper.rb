# frozen_string_literal: true
# Helper methods for hub feeds
module HubFeedsHelper
  def hub_feed_updated(hub_feed)
    updated_at =
      if hub_feed.latest_feed_items.any?
        hub_feed.latest_feed_items.first.created_at
      else
        hub_feed.feed.updated_at
      end

    updated_at.to_s(:long)
  end
end
