# frozen_string_literal: true
# Helper methods for hub feeds
module HubFeedsHelper
  def hub_feed_updated(hub_feed)
    latest_item = hub_feed.fetch_latest_feed_item

    updated_at = if latest_item && latest_item['date_published']
                   Date.parse(latest_item['date_published'])
                 else
                   hub_feed.updated_at.to_date
                 end

    updated_at.to_s(:long)
  end
end
