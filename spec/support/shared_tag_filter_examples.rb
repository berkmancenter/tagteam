shared_examples 'a tag filter' do |filter_type|
  describe '#items_in_scope' do
    include_context "user owns a hub with a feed and items"

    context 'scoped to hub' do
      it 'returns all items in the hub' do
        filter = create(filter_type, scope: @hub)
        expect(filter.items_in_scope).to match_array(@hub.feed_items)
      end
    end

    context 'scoped to feed' do
      it 'returns all items from the feed' do
        filter = create(filter_type, scope: @hub.hub_feeds.first)
        expect(filter.items_in_scope).to match_array(@hub_feed.feed_items)
      end
    end

    context 'scoped to item' do
      it 'returns the item itself' do
        filter = create(filter_type, scope: @hub.feed_items.first)
        expect(filter.items_in_scope).to match_array(@hub.feed_items.limit(1))
      end
    end
  end

  describe '#apply' do
    it 'marks the filter as applied' do
      @filter = create(filter_type)
      @filter.apply
      expect(@filter.applied).to be true
    end

    it 'will not try to create duplicate taggings' do
      @filter = create(filter_type)
      @filter.apply
      expect{ @filter.apply }.not_to raise_error
    end
  end

  describe '#rollback' do
    it 'marks the filter as not applied' do
      @filter = create(filter_type)
      @filter.apply
      @filter.rollback
      expect(@filter.applied).to be false
    end
  end

  describe '#most_recent?' do
    context 'a newer filter exists but has not been applied' do
      it 'returns true' do
        @filter1 = create(:add_tag_filter)
        @filter1.apply
        @filter2 = create(:add_tag_filter, hub: @filter1.hub)
        expect(@filter1.most_recent?).to be true
      end
    end
    context 'a newer filter has been applied' do
      it 'returns false' do
        @filter1 = create(:add_tag_filter)
        @filter1.apply
        @filter2 = create(:add_tag_filter, hub: @filter1.hub)
        @filter2.apply
        expect(@filter1.most_recent?).to be false
      end
    end

    context 'no other filters exist' do
      context 'it has been applied' do
        it 'returns true' do
          @filter = create(:add_tag_filter)
          @filter.apply
          expect(@filter.most_recent?).to be true
        end
      end

      context 'it has not been applied' do
        it 'returns false' do
          @filter = create(:add_tag_filter)
          expect(@filter.most_recent?).to be false
        end
      end
    end
     
    context 'this is the most recently applied filter' do
      it 'returns true' do
        @filter1 = create(:add_tag_filter)
        @filter1.apply
        @filter2 = create(:add_tag_filter, hub: @filter1.hub)
        @filter2.apply
        expect(@filter2.most_recent?).to be true
      end
    end
  end
end

shared_examples 'a tag filter in an empty hub' do |filter_type|
  before(:each) do
    @hub = create(:hub)
    @filter = create(filter_type, hub: @hub, scope: @hub)
  end

  describe '#deactivates_taggings' do
    it 'returns nothing' do
      expect(@filter.deactivates_taggings).to be_empty
    end
  end
end

shared_examples 'an existing tag filter in a populated hub' do
  describe '#apply' do
    it 'can be applied to only a few items in its scope' do
      random_ids = @feed_items.order('RANDOM()').limit(3).pluck(:id)
      random_items = @feed_items.where(id: random_ids)
      without_random_items = @feed_items.
        where('feed_items.id NOT IN (?)', random_ids)

      @filter.apply(items: random_items)

      tag_lists = tag_lists_for(random_items, @hub.tagging_key)
      without_tag_lists = tag_lists_for(without_random_items, @hub.tagging_key)

      expect(tag_lists).to show_effects_of @filter
      expect(without_tag_lists).to not_show_effects_of @filter
    end

    it 'owns all the taggings it creates' do
      @filter.apply
      taggings = ActsAsTaggableOn::Tagging.
        where(tag_id: @tag.id, context: @hub.tagging_key)
      expect(taggings.map(&:tagger)).to all(eq(@filter))
    end
  end

  describe '#deactivates_taggings' do
    it 'does not return its own taggings' do
      @filter.apply
      expect(@filter.deactivates_taggings.map(&:tagger).uniq).
        to not_contain @filter
    end
  end

  describe '#reactivates_taggings' do
  end

  context 'a more recent filter is applied' do
    before(:each) do
      @filter.apply
      @filter2 = create(:add_tag_filter, hub: @filter.hub)
      @filter2.apply
    end
    describe '#rollback' do
      it 'throws an error' do
        expect{ @filter.rollback }.to raise_error.with_message(/rollback/)
      end
    end
  end
end
