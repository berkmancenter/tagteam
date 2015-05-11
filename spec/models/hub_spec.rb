require 'rails_helper'

describe Hub, "#apply_tag_filters" do
  before(:each) do
    @hub = create(:hub, :with_feed)
  end

  it "makes item tags consistent with filters" do
    Sidekiq::Testing.fake! do
      new_tag = create(:tag, name: 'added-tag')
      @hub.tag_filters << create(:hub_tag_filter, type: :add, tag: new_tag)
      @hub << create(:hub_tag_filter, type: :add, tag: new_tag)
      @hub.apply_tag_filters
    end
  end

  it "returns the hub on success" do
    expect(@hub.apply_tag_filters).to eq @hub
  end
end

describe Hub, '#tag_filters' do
  it "returns all tag filters in application order" do
    hub = create(:hub, :with_feed)

    filter1 = create(:hub_tag_filter, hub: hub)
    filter2 = create(:feed_tag_filter, feed: hub.hub_feeds.first)
    filter3 = create(:item_tag_filter, item: hub.hub_feeds.first.feed_items.first)
    filter4 = create(:hub_tag_filter, hub: hub)

    expect(hub.tag_filters).to eq [filter1, filter2, filter3]
  end
end
