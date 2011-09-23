require 'net/http'
require 'net/https'
require 'uri'

module FeedUtilities

	# Attempts to download and parse a single feed to see if we think it's RSS, Atom, or some other syndication format.
	#
	# === Parameters
	# [feed] An instance of the feed model you'd like to test. Sets ActiveRecord errors on the feed_url attribute if it fails. On success, it sets the feed title, description, url and other basic attributes.
	# === Returns
	# "false" in the case of failure to be caught during an ActiveRecord validation sequence.
	def test_single_feed(feed)
		begin
			response = fetch(feed.feed_url)
		rescue
			self.errors.add(:feed_url, "couldn't be downloaded. Please check the URL to ensure it's a supported syndication format.")
			return false
		end

    parsed_feed = ''

    begin 
      parsed_feed = FeedAbstract::Feed.new(response.body)
    rescue
      self.errors.add(:feed_url, "didn't look like a syndication feed in a supported format- RSS or Atom, for instance.")
      return false
    end

    feed.title = parsed_feed.channel.title
		feed.description = parsed_feed.channel.description
    feed.guid = parsed_feed.channel.guid
    if parsed_feed.channel.updated.respond_to?(:to_datetime)
      feed.last_updated = parsed_feed.channel.updated.to_datetime
    end
    feed.rights = parsed_feed.channel.rights
    feed.authors = parsed_feed.channel.author
    feed.link = parsed_feed.channel.link
    feed.generator = parsed_feed.channel.generator
    feed.language = parsed_feed.channel.language
		feed.raw_feed = parsed_feed
  end
  
  def update_feed
  
    
  end
	
	# Downloads a URL
	# === Parameters
	# [uri] The URI to download.
	# [redirect_limit] Allow this many redirects before quitting. Defaults to 10
  # [sleep] Wait this many seconds in between redirects. Defaults to 1.
	# === Returns
	# The Net::HTTP::Response object, or throws an error on failure.
	def fetch(uri, redirect_limit = 10, sleep_seconds = 1)
		raise ArgumentError, 'HTTP redirect too deep' if redirect_limit == 0
		if redirect_limit < 10
			#On subsequent requests in a request with redirections, wait a second
			sleep sleep_seconds
		end
		url = URI.parse(uri)
		req = Net::HTTP::Get.new(url.request_uri + ((url.fragment.blank?) ? '' : '#' + url.fragment ))
		req.initialize_http_header({"User-Agent" => ROBOT_USER_AGENT})

    # logger.warn(url.inspect)
    # logger.warn(url.port)
    # logger.warn(url.host)
		http = Net::HTTP::new(url.host,url.port)
		if url.scheme == 'https'
			http.use_ssl = true
			# Get rid of these errors:
			# warning: peer certificate won't be verified in this SSL session
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		end

		response = http.request(req)

		case response
		when Net::HTTPSuccess     then response
		when Net::HTTPRedirection then fetch(response['location'], redirect_limit - 1)
		else
			response.error!
		end
	end

end
