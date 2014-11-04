class UpdateFeeds
  include Sidekiq::Worker
  sidekiq_options queue: :updater, retry: false

  def self.display_name
    "Looking for new or changed feed items"
  end

  def perform
    feeds = HubFeed.need_updating
    feeds.each do|hf|
      hf.feed.update_feed
    end
  end

end
