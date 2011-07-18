module FeedUtilities

  def get_and_parse_feed(feed)
		parsed_feed = Feedzirra::Feed.fetch_and_parse(feed.feed_url)
		
		return parsed_feed
  end

end
