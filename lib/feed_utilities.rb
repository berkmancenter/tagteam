module FeedUtilities

  def get_and_parse_single_feed(feed)
		parsed_feed = Feedzirra::Feed.fetch_and_parse([feed.feed_url])
    if parsed_feed[feed.feed_url].blank? || parsed_feed[feed.feed_url].to_s.match(/^\d+$/) || parsed_feed[feed.feed_url].entries.length == 0
      feed.errors.add(:feed_url, "doesn't appear to be a valid RSS feed.")
      return false
    end
    pfeed = parsed_feed[feed.feed_url]
    feed.title = pfeed.title
    feed.etag = pfeed.etag
    feed.url = pfeed.url
    feed.flavor = RSS_FLAVORS[pfeed.class]
    return pfeed

  end



end
