# frozen_string_literal: true
require 'rails_helper'
require 'support/shared_context'
require 'support/tag_utils'

RSpec.describe UpdateFeeds, type: :worker do
  describe 'updating feeds' do
    include_context 'user owns a hub with a feed and items'

    it 'continues the process after an error in one of the feeds' do
      VCR.use_cassette('update_feeds') do
        expect(@hub.feed_items.count).to eq(10)
        feed_ok = create(:feed, feed_url: 'http://www.reddit.com/r/news/.rss?copy=0')
        create(:hub_feed, feed: feed_ok, hub: @hub)
        feed_broken = create(:feed, feed_url: 'http://peterh.info/test_ok.xml?copy=0')
        create(:hub_feed, feed: feed_broken, hub: @hub)
        @hub.feed_items.destroy_all

        expect(@hub.feed_items.count).to eq(0)

        feed_ok.next_scheduled_retrieval = feed_broken.next_scheduled_retrieval = 1.day.ago
        feed_ok.save!
        feed_broken.save!

        feed_broken.feed_url = 'http://peterh.info/test_broken.xml?copy=0'
        feed_broken.save!

        described_class.perform_async
        expect(@hub.feed_items.count).to eq(25)
      end
    end
  end
end
