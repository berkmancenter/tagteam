class Feed < ActiveRecord::Base
  include FeedUtilities
  include AuthUtilities
  acts_as_authorization_object

	attr_accessible :feed_url
  validates_presence_of :feed_url

#  before_save :get_and_parse_feed

	before_validation do
		return false if feed_url.blank?
		if ! feed_url.match(/https?:\/\/.+/i).nil?
			rss_feed = get_and_parse_single_feed(self)
      return false unless rss_feed
		else
			return false
		end
	end

end
