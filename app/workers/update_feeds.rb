class UpdateFeeds
  @queue = :updater

  def self.display_name
    "Looking for new or changed feed items"
  end

  def self.perform
    feeds = HubFeed.need_updating
    feeds.each do|hf|
      hf.feed.update_feed
      hf.hub.update_all_tag_count
    end
  end
end
