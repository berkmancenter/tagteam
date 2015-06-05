shared_examples TagFilter do |filter_type|
  describe '#items_in_scope' do
    include_context "user owns a hub with a feed and items"
    context 'scoped to hub' do
      it 'returns all items in the hub' do
        filter = create(:tag_filter, scope: @hub)
        expect(filter.items_in_scope).to match_array(@hub.feed_items)
      end
    end

    context 'scoped to feed' do
      it 'returns all items from the feed' do
        filter = create(:tag_filter, scope: @hub.hub_feeds.first)
        expect(filter.items_in_scope).to match_array(@hub.hub_feeds.feed_items)
      end
    end

    context 'scoped to item' do
      it 'returns the item itself' do
        filter = create(:tag_filter, scope: @hub.feed_items.first)
        expect(filter.items_in_scope).to match_array(@hub.feed_items.limit(1))
      end
    end
  end
end
