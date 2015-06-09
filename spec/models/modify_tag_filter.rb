require 'rails_helper'

describe ModifyTagFilter do
  describe '#description' do
    it 'returns "Change"' do
      expect(create(:modify_tag_filter).description).to eq('Change')
    end
  end

  context 'the filter is scoped to a hub with some items with tag "a"' do
    include_context 'user owns a hub with a feed and items'
    before(:each) do
      @tag = create(:tag, name: 'a')
      @feed_items.limit(4).each do |item|
        create(:tagging, tag: @tag, taggable: item, tagger: item.feeds.first)
        # This doesn't run on its own because items have already been created.
        item.copy_tags_to_hubs
      end
    end
    context 'the filter changes tag "a" to tag "b"' do
      before(:each) do
        @new_tag = create(:tag, name: 'b')
        @filter = create(:modify_tag_filter, hub: @hub, tag: @tag,
                         new_tag: @new_tag, scope: @hub)
      end

      describe '#apply' do
        it 'creates taggings for tag "b"' do
          @filter.apply
          taggings = ActsAsTaggableOn::Tagging.
            where(tag_id: @new_tag.id, context: @hub.tagging_key)
          expect(taggings.count).to be > 0
        end

        it 'deactivates all tag "a" taggings' do
          @filter.apply
          taggings = ActsAsTaggableOn::Tagging.
            where(tag_id: @tag.id, context: @hub.tagging_key)
          expect(taggings.count).to eq(0)
        end

        it 'replaces all tag "a" taggings with tag "b" taggings' do
          @filter.apply
          tag_lists = tag_lists_for(@hub.feed_items, @hub.tagging_key)
          expect(tag_lists).to show_effects_of @filter
        end
      end

      describe '#rollback' do
        it 'deletes any owned taggings' do
          @filter.apply
          query = ActsAsTaggableOn::Tagging.
            where(tagger_id: @filter.id, tagger_type: @filter.class.base_class.name)
          expect(query.count).to be > 0
          @filter.rollback
          expect(query.count).to eq(0)
        end

        it 'reactivates all tag "a" taggings' do
          pre_filter_taggings = @feed_items.map(&:taggings).flatten
          @filter.apply
          @filter.rollback
          post_rollback_taggings = @feed_items.map(&:taggings).flatten
          expect(pre_filter_taggings).to match_array(post_rollback_taggings)
        end
      end

      describe '#deactivates_taggings' do
        context 'a feed item exists with tag "a" and tag "b"' do
          before(:each) do
            @feed_item = create(:feed_item, :tagged, tag: 'b',
                                tag_context: @hub.tagging_key)
            create(:tagging, taggable: @feed_item, tag: @tag,
                   context: @hub.tagging_key)
          end
          it 'returns both taggings', wip: true do
            expect(@filter.deactivates_taggings).
              to include(*@feed_item.taggings.all)
          end
        end

        context 'a feed item exists with tag "b" but not tag "a"' do
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

      context 'active taggings already exist between tag "b" and items' do
        before(:each) do
          @tagged_feed_items = create_list(
            :feed_item_from_feed, 3, :tagged, feed: @hub_feed.feed,
            tag: 'b', tag_context: @hub.tagging_key)
        end

        describe '#apply' do
          it 'deactivates all previous tag "b" taggings' do
            taggings = ActsAsTaggableOn::Tagging.
              where(tag_id: @new_tag.id).all.
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
              where(tag_id: @new_tag.id).all.
              map{ |tagging| tagging.becomes ActsAsTaggableOn::Tagging }
            @filter.rollback
            expect(DeactivatedTagging.count).to eq(0)
            expect(ActsAsTaggableOn::Tagging.all).to include(*taggings)
          end
        end

        describe '#deactivates_taggings' do
          it 'returns the taggings attaching tag "b" to those feed items' do
            expect(@filter.deactivates_taggings).
              to match_array(@tagged_feed_items.map(&:taggings).flatten)
          end
        end
      end

      it_behaves_like 'an existing tag filter in a populated hub'
    end
  end

  it_behaves_like 'a tag filter in an empty hub', :modify_tag_filter
  it_behaves_like 'a tag filter', :modify_tag_filter
  # An item comes in from an external feed with tags 'tag1' and 'tag2'.
  # We add a hub filter that changes 'tag1' to 'tag2'
  # Both taggings on the item should be deactivated, as the 'tag2' tagging
  # should now be owned by the filter, not the external feed.
  #
  # An item comes in from an external feed with tag 'tag2'.
  # We add a hub filter that changes 'tag1' to 'tag2'
  # We shouldn't touch the external feed's tagging of 'tag2'.
end
