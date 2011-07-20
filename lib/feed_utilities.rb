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

		parsed_feed = FeedNormalizer::FeedNormalizer.parse(response.body)
		if parsed_feed.nil?
			self.errors.add(:feed_url, "didn't look like a syndication feed in a supported format- RSS or Atom, for instance.")
			return false
		end

    feed.title = parsed_feed.title
		feed.description = parsed_feed.description
    feed.url = parsed_feed.url
		feed.raw_feed = parsed_feed
  end
	
	# Downloads a URL
	# === Parameters
	# [uri] The URI to download.
	# [redirect_limit] Allow this many redirects before quitting. Defaults to 10
	# === Returns
	# The Net::HTTP::Response object, or throws an error on failure.
	def fetch(uri, redirect_limit = 10)
		raise ArgumentError, 'HTTP redirect too deep' if redirect_limit == 0
		if redirect_limit < 10
			#On subsequent requests in a request with redirections, wait a second
			sleep 1
		end
		url = URI.parse(uri)
		req = Net::HTTP::Get.new(url.request_uri + ((url.fragment.blank?) ? '' : '#' + url.fragment ))
		req.initialize_http_header({"User-Agent" => "tagteam social RSS aggregrator 0.1: http://github.com/berkmancenter/taghub"})

		http = Net::HTTP::new(url.host,url.port)
		if(url.scheme == 'https')
			http.use_ssl = true
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
