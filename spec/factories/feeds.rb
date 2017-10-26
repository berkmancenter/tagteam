# frozen_string_literal: true

FactoryBot.define do
  factory :feed do
    before(:create) do |feed|
      uri = URI(feed.feed_url)
      copy = CGI.parse(uri.query)['copy'].first
      cassette = "feed_factory-#{uri.host}-#{copy}"
      VCR.insert_cassette(cassette)
    end

    after(:create) { VCR.eject_cassette }

    transient do
      with_url 0
      copy 0
    end

    feed_url do |feed|
      feeds = [
        'http://reagle.org/joseph/blog/?flav=atom',
        'http://childrenshospitalblog.org/category/claire-mccarthy-md/feed/?1=1',
        'http://feeds.feedburner.com/mfeldstein/feed/?1=1'
      ]
      feeds[feed.with_url % feeds.size] + "&copy=#{feed.copy}"
    end

    initialize_with { Feed.find_or_create_by(feed_url: feed_url) }
  end
end
