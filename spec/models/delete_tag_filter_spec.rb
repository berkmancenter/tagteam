require 'rails_helper'

describe DeleteTagFilter do
  describe '#description' do
    it 'returns "Delete"' do
      expect(create(:delete_tag_filter).description).to eq('Delete')
    end
  end

  context 'the filter is scoped to a hub with items all with tag "a"' do
    include_context 'user owns a hub with a feed and items'
    before(:each) do
      @tag = create(:tag, name: 'a')
      @feed_items.each do |item|
        create(:tagging, tag: @tag, taggable: item, tagger: item.feeds.first)
        # This doesn't run on its own because items have already been created.
        item.copy_tags_to_hubs
      end
    end
    context 'the filter deletes tag "a"' do
      before(:each) do
        @filter = create(:delete_tag_filter, hub: @hub, tag: @tag, scope: @hub)
      end

      describe '#apply' do
        it 'deletes taggings' do
          query = ActsAsTaggableOn::Tagging.
            where(tag_id: @tag.id, context: @hub.tagging_key)
          pre_taggings = query.count
          @filter.apply
          post_taggings = query.count
          expect(pre_taggings).to be > post_taggings
        end

        it 'deletes tag "a" from all items in the hub' do
          @filter.apply
          tag_lists = tag_lists_for(@hub.feed_items, @hub.tagging_key)
          expect(tag_lists).to show_effects_of @filter
        end
      end

      describe '#rollback' do
        it 'restores tag "a" to all items' do
          @filter.apply
          @filter.rollback
          tag_lists = tag_lists_for(@hub.feed_items, @hub.tagging_key)
          expect(tag_lists).to all(include('a'))
        end
      end

      describe '#deactivates_taggings' do
        it 'returns all tag "a" taggings' do
          taggings = ActsAsTaggableOn::Tagging.
            where(context: @hub.tagging_key, tag_id: @tag.id)
          expect(@filter.deactivates_taggings).to match_array(taggings)
        end

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

      it_behaves_like 'an existing tag filter in a populated hub'
    end
  end

  it_behaves_like 'a tag filter in an empty hub', :delete_tag_filter
  it_behaves_like 'a tag filter', :delete_tag_filter
end

