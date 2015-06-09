require 'rails_helper'

describe AddTagFilter do
  include_examples TagFilter

  describe '#apply' do
    it 'marks the filter as applied' do
      @filter = create(:add_tag_filter)
      @filter.apply
      expect(@filter.applied).to be true
    end

    context 'the filter is scoped to a hub with items' do
      include_context 'user owns a hub with a feed and items'
      context 'the filter adds tag "a"' do
        before(:each) do
          @tag = create(:tag, name: 'a')
          @filter = create(:add_tag_filter, hub: @hub, tag: @tag, scope: @hub)
        end

        it 'adds the tag "a" to all items in the hub' do
          @filter.apply
          tag_lists = tag_lists_for(@hub.feed_items, ['tags', @hub.tagging_key])
          expect(tag_lists).to show_effects_of @filter
        end

        it 'owns all the taggings it creates' do
          @filter.apply
          taggings = ActsAsTaggableOn::Tagging.
            where(tag_id: @tag.id, context: @hub.tagging_key)
          expect(taggings.count).to be > 0
          expect(taggings.map(&:tagger)).to all(eq(@filter))
        end

        it 'will not try to create duplicate taggings' do
          @filter.apply
          expect{ @filter.apply }.not_to raise_error
        end

        it 'can apply taggings to only a few items in its scope' do
          random_items = @feed_items.order('RANDOM()').limit(3)
          without_random_items = @feed_items.
            where('feed_items.id NOT IN (?)', random_items.pluck(:id))
          contexts = ['tags', @hub.tagging_key]

          @filter.apply(items: random_items)

          tag_lists = tag_lists_for(random_items, contexts)
          without_tag_lists = tag_lists_for(without_random_items, contexts)

          expect(tag_lists).to show_effects_of @filter
          expect(without_tag_lists).to not_show_effects_of @filter
        end

        context 'active taggings already exist between tag "a" and items' do
          before(:each) do
            @tagged_feed_items = create_list(
              :feed_item_from_feed, 3, :tagged, feed: @hub_feed.feed,
              tag: 'a', tag_context: @hub.tagging_key)
          end
          it 'deactivates all previous tag "a" taggings' do
            taggings = ActsAsTaggableOn::Tagging.
              where(tag_id: @tag.id).all.
              map{ |tagging| tagging.becomes DeactivatedTagging }

            @filter.apply

            expect(DeactivatedTagging.count).to be > 0
            expect(DeactivatedTagging.unscoped).to match_array(taggings)
          end

          it 'does not deactivate irrelevant taggings' do
            @filter.apply
            expect(DeactivatedTagging.unscoped.pluck(:tag_id)).
              to all(eq(@filter.tag_id))
          end
        end
      end
    end
  end

  describe '#rollback' do
    it 'marks the filter as not applied' do
      @filter = create(:add_tag_filter)
      @filter.apply
      @filter.rollback
      expect(@filter.applied).to be false
    end

    context 'the filter is scoped to a hub with items' do
      include_context 'user owns a hub with a feed and items'
      context 'the filter adds tag "a"' do
        before(:each) do
          @tag = create(:tag, name: 'a')
          @filter = create(:add_tag_filter, hub: @hub, tag: @tag, scope: @hub)
        end

        it 'deletes any owned taggings' do
          @filter.apply
          query = ActsAsTaggableOn::Tagging.where(tagger_id: @filter.id,
                                                  tagger_type: TagFilter)
          expect(query.count).to be > 0
          @filter.rollback
          expect(query.count).to eq(0)
        end

        context 'active taggings already exist between tag "a" and items' do
          before(:each) do
            @tagged_feed_items = create_list(
              :feed_item_from_feed, 3, :tagged, feed: @hub_feed.feed,
              tag: 'a', tag_context: @hub.tagging_key)
            @filter.apply
          end
          it 'reactivates deactived taggings' do
            taggings = DeactivatedTagging.
              where(tag_id: @tag.id).all.
              map{ |tagging| tagging.becomes ActsAsTaggableOn::Tagging }
            @filter.rollback
            expect(DeactivatedTagging.count).to eq(0)
            expect(ActsAsTaggableOn::Tagging.all).to include(*taggings)
          end

          context 'a newer filter exists that deactivates some taggings' do
            before(:each) do
              @new_feed = create(:feed, with_url: 1)
              @hub.feeds << @new_feed
              @new_hub_feed = @hub.hub_feeds.where(feed_id: @new_feed.id).first
              @filter.apply
              @feed_filter = create(:add_tag_filter, hub: @hub,
                                    tag: @tag, scope: @new_hub_feed)
              @feed_filter.apply
            end
            it 'throws an error if it is not the most recent filter' do
              expect{ @filter.rollback }.to raise_error.with_message(/rollback/)
            end
          end
        end
      end
    end
  end

  describe '#description' do
    it 'returns "Add"' do
      expect(create(:add_tag_filter).description).to eq('Add')
    end
  end

  describe '#deactivates_taggings' do
    context 'the filter is scoped to a hub with no items' do
      before(:each) do
        @hub = create(:hub)
        @tag = create(:tag, name: 'a')
        @filter = create(:add_tag_filter, hub: @hub, tag: @tag, scope: @hub)
      end

      it 'returns nothing' do
        expect(@filter.deactivates_taggings).to be_empty
      end
    end

    context 'the filter is scoped to a hub with items' do
      include_context 'user owns a hub with a feed and items'
      context 'the filter adds tag "a"' do
        before(:each) do
          @tag = create(:tag, name: 'a')
          @filter = create(:add_tag_filter, hub: @hub, tag: @tag, scope: @hub)
        end

        it 'does not return its own taggings' do
          @filter.apply
          expect(@filter.deactivates_taggings.map(&:tagger).uniq).
            to not_contain @filter
        end

        context 'a feed item exists with tag "a"' do
          before(:each) do
            @feed_item = create(:feed_item_from_feed, :tagged,
                                feed: @hub_feed.feed, tag: 'a',
                                tag_context: @hub.tagging_key)
          end
          it 'returns the tagging attaching tag "a" to that feed item' do
            expect(@feed_item.taggings.count).to be > 0
            expect(@filter.deactivates_taggings).
              to match_array(@feed_item.taggings)
          end
        end

        context 'a feed item exists with tag "b"' do
          before(:each) do
            @feed_item = create(:feed_item, :tagged, tag: 'b',
                                tag_context: @hub.tagging_key)
          end
          it 'returns nothing' do
            expect(@filter.deactivates_taggings).to be_empty
          end
        end
      end
    end
  end

  describe '#reactivates_taggings' do
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
