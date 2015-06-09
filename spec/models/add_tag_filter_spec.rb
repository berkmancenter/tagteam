require 'rails_helper'

describe AddTagFilter do
  describe '#description' do
    it 'returns "Add"' do
      expect(create(:add_tag_filter).description).to eq('Add')
    end
  end

  context 'the filter is scoped to a hub with items' do
    include_context 'user owns a hub with a feed and items'
    context 'the filter adds tag "a"' do
      before(:each) do
        @tag = create(:tag, name: 'a')
        @filter = create(:add_tag_filter, hub: @hub, tag: @tag, scope: @hub)
      end

      describe '#apply' do
        it 'creates taggings' do
          @filter.apply
          taggings = ActsAsTaggableOn::Tagging.
            where(tag_id: @tag.id, context: @hub.tagging_key)
          expect(taggings.count).to be > 0
        end

        it 'adds the tag "a" to all items in the hub' do
          @filter.apply
          tag_lists = tag_lists_for(@hub.feed_items, @hub.tagging_key)
          expect(tag_lists).to show_effects_of @filter
        end
      end

      describe '#rollback' do
        it 'deletes any owned taggings' do
          @filter.apply
          query = ActsAsTaggableOn::Tagging.where(tagger_id: @filter.id,
                                                  tagger_type: TagFilter)
          expect(query.count).to be > 0
          @filter.rollback
          expect(query.count).to eq(0)
        end
      end

      describe '#deactivates_taggings' do
        context 'a feed item exists with tag "b"' do
          before(:each) do
            @feed_item = create(:feed_item, :tagged, tag: 'b',
                                tag_context: @hub.tagging_key)
          end
          it 'does not return that tagging' do
            expect(@filter.deactivates_taggings).
              to not_contain @feed_item.taggings.first
          end
        end
      end

      context 'active taggings already exist between tag "a" and items' do
        before(:each) do
          @tagged_feed_items = create_list(
            :feed_item_from_feed, 3, :tagged, feed: @hub_feed.feed,
            tag: 'a', tag_context: @hub.tagging_key)
        end

        describe '#apply' do
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

        describe '#rollback' do
          it 'reactivates deactived taggings' do
            @filter.apply
            taggings = DeactivatedTagging.
              where(tag_id: @tag.id).all.
              map{ |tagging| tagging.becomes ActsAsTaggableOn::Tagging }
            @filter.rollback
            expect(DeactivatedTagging.count).to eq(0)
            expect(ActsAsTaggableOn::Tagging.all).to include(*taggings)
          end
        end

        describe '#deactivates_taggings' do
          it 'returns the taggings attaching tag "a" to those feed items' do
            expect(@filter.deactivates_taggings).
              to match_array(@tagged_feed_items.map(&:taggings).flatten)
          end
        end
      end

      it_behaves_like 'an existing tag filter in a populated hub'
    end
  end

  it_behaves_like 'a tag filter in an empty hub', :add_tag_filter
  it_behaves_like 'a tag filter', :add_tag_filter
end
