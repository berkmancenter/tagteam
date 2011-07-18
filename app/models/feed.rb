class Feed < ActiveRecord::Base
  include FeedUtilities
  include AuthUtilities

	attr_accessor :feed_url

#  before_save :get_and_parse_feed

	before_validation(:on => :create) do
		return false if feed_url.blank?
		if ! feed_url.match(/https?:\/\/.+/i).nil?
			rss_feed = get_and_parse_feed(self)
			logger.warn('title: ' + rss_feed.title)
		else
			return false
		end
	end

end
