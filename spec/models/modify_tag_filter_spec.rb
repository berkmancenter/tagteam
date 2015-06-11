require 'rails_helper'

describe ModifyTagFilter do
  context 'the filter is scoped to a hub with some items with tag "a"' do
    include_context 'user owns a hub with a feed and items'
    before(:each) do
      @tag = create(:tag, name: 'a')
      @feed_items.limit(4).each do |item|
        create(:tagging, tag: @tag, taggable: item, tagger: item.feeds.first)
        # This doesn't run on its own because items have already been created.
        item.copy_global_tags_to_hubs
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
            @feed_item = create(:feed_item_from_feed, :tagged,
                                feed: @hub_feed.feed, tag: 'b',
                                tag_context: @hub.tagging_key)
            create(:tagging, taggable: @feed_item, tag: @tag,
                   context: @hub.tagging_key)
          end
          it 'returns both taggings' do
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

      it_behaves_like 'an existing tag filter in a populated hub'
    end
  end

  context "the filter is scoped to a hub" do
    def add_filter(old_tag = 'social', new_tag = 'not-social')
      filter = create(:modify_tag_filter,
        tag: ActsAsTaggableOn::Tag.find_by_name(old_tag),
        new_tag: create(:tag, name: new_tag),
        hub: @hub, scope: @hub
      )
      filter
    end

    def filter_list
      @hub.tag_filters
    end

    context "user owns a hub with a feed and items" do
      include_context "user owns a hub with a feed and items"

      it "modifies tags" do
        old_tag = 'social'
        new_tag = 'not-social'

        filter = add_filter(old_tag, new_tag)
        filter.apply
        new_tag_lists = tag_lists_for(@feed_items.reload, @hub.tagging_key, true)

        expect(new_tag_lists).to show_effects_of filter
      end

    end

    it_behaves_like "a hub-level tag filter"
  end

  context "the filter is scoped to a feed" do
    def add_filter(old_tag = 'social', new_tag = 'not-social')
      create(:modify_tag_filter,
        tag: ActsAsTaggableOn::Tag.find_by_name(old_tag),
        new_tag: create(:tag, name: new_tag),
        hub: @hub, scope: @hub_feed
      )
    end

    def filter_list
      @hub_feed.tag_filters
    end

    def setup_other_feeds_tags(filter, hub_feed)
      filter = create(:add_tag_filter, tag: filter.tag, hub: hub_feed.hub,
                      scope: hub_feed)
      filter.apply
    end

    context "user owns a hub with a feed and items" do
      include_context "user owns a hub with a feed and items"

      it "modifies tags" do
        old_tag = 'social'
        new_tag = 'not-social'

        filter = add_filter(old_tag, new_tag)
        filter.apply
        new_tag_lists = tag_lists_for(@feed_items.reload, @hub.tagging_key, true)

        expect(new_tag_lists).to show_effects_of filter
      end

    end

    it_behaves_like "a feed-level tag filter"
  end

  context "the filter is scoped to an item" do
    def add_filter(old_tag = 'social', new_tag = 'not-social')
      create(:modify_tag_filter,
        tag: ActsAsTaggableOn::Tag.find_by_name(old_tag),
        new_tag: create(:tag, name: new_tag),
        hub: @hub, scope: @feed_item
      )
    end

    def filter_list
      @feed_item.tag_filters
    end

    def setup_other_items_tags(filter, item)
      filter = create(:add_tag_filter, tag: filter.tag, hub: @hub,
                      scope: item)
      filter.apply
    end

    context "user owns a hub with a feed and items" do
      include_context "user owns a hub with a feed and items"

      it "modifies tags" do
        @feed_item = @feed_items.first
        old_tag = 'social'
        new_tag = 'not-social'

        filter = add_filter(old_tag, new_tag)
        filter.apply

        new_tag_lists = tag_lists_for(@feed_item, @hub.tagging_key)
        expect(new_tag_lists).to show_effects_of filter
      end

    end

    it_behaves_like "an item-level tag filter"
  end

  it_behaves_like 'a tag filter in an empty hub', :modify_tag_filter
  it_behaves_like 'a tag filter', :modify_tag_filter
end
