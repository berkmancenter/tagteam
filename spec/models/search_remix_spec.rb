# frozen_string_literal: true
require 'rails_helper'

RSpec.describe SearchRemix, type: :model, needs_review: true do
  it 'returns the ids for a given search string and hub' do
    pending('This test is pending')
    feed_item = FeedItem.last
    hub_feed = feed_item.hub_feeds.first
    hub = hub_feed.hub

    search_stub = double('Sunspot::Search', results: [feed_item], execute!: true)

    FeedItem.should_receive(:search) { search_stub }

    s = SearchRemix.create! search_string: '#parenting', hub: hub
    results = SearchRemix.search_results_for s.id

    results.should == [feed_item.id]
  end
end
