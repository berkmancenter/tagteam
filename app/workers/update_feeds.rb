class UpdateFeeds
  @queue = :update_feeds

  def self.perform
    feeds = HubFeed.need_updating
    feeds.each do|hf|
  #    puts "Updating #{hf.feed.feed_url} "
      hf.feed.update_feed
    end
  end

end
