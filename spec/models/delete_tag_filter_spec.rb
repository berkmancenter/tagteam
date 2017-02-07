# frozen_string_literal: true
require 'rails_helper'

RSpec.describe DeleteTagFilter, type: :model do
  context 'the filter is scoped to a hub with items all with tag "a"' do
    include_context 'user owns a hub with a feed and items'
    before do
      @tag = create(:tag, name: 'a')
      @feed_items.each do |item|
        create(:tagging, tag: @tag, taggable: item, tagger: item.feeds.first)
        # This doesn't run on its own because items have already been created.
        item.copy_global_tags_to_hubs
      end
    end
    context 'the filter deletes tag "a"' do
      before do
        @filter = create(:delete_tag_filter, hub: @hub, tag: @tag, scope: @hub)
      end

      describe '#apply' do
        it 'deletes taggings' do
          query = ActsAsTaggableOn::Tagging
                  .where(tag_id: @tag.id, context: @hub.tagging_key)
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
          taggings = ActsAsTaggableOn::Tagging
                     .where(context: @hub.tagging_key, tag_id: @tag.id)
          expect(@filter.deactivates_taggings).to match_array(taggings)
        end

        context 'a feed item exists with tag "b"' do
          before do
            @feed_item = create(:feed_item, :tagged, tag: 'b',
                                                     tag_context: @hub.tagging_key)
          end
          it 'does not return that tagging' do
            expect(@filter.deactivates_taggings)
              .to not_contain @feed_item.taggings.first
          end
        end
      end

      describe '#simulate' do
        it 'removes "a" in a given tag list' do
          list = %w(a b c d)
          expect(@filter.simulate(list)).to match_array(%w(b c d))
        end
      end

      it_behaves_like 'an existing tag filter in a populated hub'
    end
  end

  context 'the filter is scoped to a hub' do
    def add_filter(old_tag = 'social')
      filter = create(:delete_tag_filter,
                      tag: ActsAsTaggableOn::Tag.find_by(name: old_tag),
                      hub: @hub, scope: @hub)
      filter
    end

    def filter_list
      @hub.tag_filters
    end

    context 'user owns a hub with a feed and items' do
      include_context 'user owns a hub with a feed and items'

      it 'removes tags' do
        deleted_tag = 'social'

        filter = add_filter(deleted_tag)
        filter.apply

        tag_lists = tag_lists_for(@feed_items, @hub.tagging_key)
        expect(tag_lists).to show_effects_of filter
      end
    end

    it_behaves_like 'a hub-level tag filter'
  end

  context 'the filter is scoped to a feed' do
    def add_filter(old_tag = 'social')
      create(:delete_tag_filter,
             tag: ActsAsTaggableOn::Tag.find_by(name: old_tag),
             hub: @hub, scope: @hub_feed)
    end

    def filter_list
      @hub_feed.tag_filters
    end

    def setup_other_feeds_tags(filter, hub_feed)
      filter = create(:add_tag_filter, tag: filter.tag,
                                       hub: hub_feed.hub, scope: hub_feed)
      filter.apply
    end

    context 'user owns a hub with a feed and items' do
      include_context 'user owns a hub with a feed and items'

      it 'removes tags' do
        deleted_tag = 'social'

        filter = add_filter(deleted_tag)
        filter.apply

        tag_lists = tag_lists_for(@feed_items, @hub.tagging_key)
        expect(tag_lists).to show_effects_of filter
      end
    end

    it_behaves_like 'a feed-level tag filter'
  end

  context 'the filter is scoped to an item' do
    def add_filter(old_tag = 'social')
      create(:delete_tag_filter, tag: ActsAsTaggableOn::Tag.find_by(name: old_tag),
                                 hub: @hub, scope: @feed_item)
    end

    def filter_list
      @feed_item.tag_filters
    end

    def setup_other_items_tags(filter, item)
      filter = create(:add_tag_filter, tag: filter.tag, hub: @hub, scope: item)
      filter.apply
    end

    context 'user owns a hub with a feed and items' do
      include_context 'user owns a hub with a feed and items'

      it 'removes tags' do
        @feed_item = @feed_items.first
        deleted_tag = 'social'

        filter = add_filter(deleted_tag)

        tag_lists = tag_lists_for(@feed_item, @hub.tagging_key)
        expect(tag_lists).to show_effects_of filter
      end
    end

    it_behaves_like 'an item-level tag filter'
  end

  it_behaves_like 'a tag filter in an empty hub', :delete_tag_filter
  it_behaves_like 'a tag filter', :delete_tag_filter
end
