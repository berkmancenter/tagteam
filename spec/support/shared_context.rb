shared_context "user owns a hub with a feed and items" do
  before(:each) do
    @user = create(:confirmed_user)
    @hub = create(:hub, :with_feed, :owned, with_feed_url: 0, owner: @user)
    @hub_feed = @hub.hub_feeds.first
    @feed_items = @hub_feed.feed_items
  end
end
