# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SupplementTagFilter, type: :model do
  it_behaves_like 'a tag filter in an empty hub', :supplement_tag_filter
  it_behaves_like 'a tag filter', :supplement_tag_filter

  def new_add_filter(tag_name = 'just-a-tag')
    new_tag = create(:tag, name: tag_name)
    create(:add_tag_filter, tag: new_tag, hub: @hub, scope: @hub)
  end

  context 'when the filter is scoped to a hub' do
    def add_filter(old_tag = 'just-a-tag', new_tag = 'not-just-a-tag')
      unless ActsAsTaggableOn::Tag.find_by(name: old_tag)
        create(:tag, name: old_tag)
      end

      filter = create(:supplement_tag_filter,
                      tag: ActsAsTaggableOn::Tag.find_by(name: old_tag),
                      new_tag: create(:tag, name: new_tag),
                      hub: @hub, scope: @hub)
      filter
    end

    def filter_list
      @hub.tag_filters
    end

    context 'user owns a hub with a feed and items' do
      include_context 'user owns a hub with a feed and items'

      it 'adds the supplemental tags' do
        old_tag_name = 'just-a-tag'
        new_tag_name = 'not-just-a-tag'

        old_tag = create(:tag, name: old_tag_name)
        create(:tagging, tag: old_tag, taggable: @feed_items.first,
                         context: @hub.tagging_key)

        filter = add_filter(old_tag_name, new_tag_name)
        filter.apply

        new_tag_lists = tag_lists_for(@feed_items.reload, @hub.tagging_key)

        expect(new_tag_lists).to show_effects_of filter
      end
    end

    it_behaves_like 'a hub-level tag filter'
  end

  context 'when the filter is scoped to a feed' do
    def add_filter(old_tag = 'just-a-tag', new_tag = 'not-just-a-tag')
      unless ActsAsTaggableOn::Tag.find_by(name: old_tag)
        create(:tag, name: old_tag)
      end

      create(:supplement_tag_filter,
             tag: ActsAsTaggableOn::Tag.find_by(name: old_tag),
             new_tag: create(:tag, name: new_tag),
             hub: @hub, scope: @hub_feed)
    end

    def filter_list
      @hub_feed.tag_filters
    end

    def setup_other_feeds_tags(filter, hub_feed)
      filter = create(:add_tag_filter, tag: filter.tag, hub: hub_feed.hub,
                                       scope: hub_feed)
      filter.apply
    end

    context 'user owns a hub with a feed and items' do
      include_context 'user owns a hub with a feed and items'

      it 'adds the supplemental tags' do
        old_tag = 'just-a-tag'
        new_tag = 'not-just-a-tag'

        filer_old = new_add_filter(old_tag)
        filer_old.apply

        filter = add_filter(old_tag, new_tag)
        filter.apply

        new_tag_lists = tag_lists_for(@feed_items.reload, @hub.tagging_key, true)

        expect(new_tag_lists).to show_effects_of filter
      end
    end

    it_behaves_like 'a feed-level tag filter'
  end

  context 'when the filter is scoped to an item' do
    def add_filter(old_tag = 'just-a-tag', new_tag = 'not-just-a-tag')
      unless ActsAsTaggableOn::Tag.find_by(name: old_tag)
        create(:tag, name: old_tag)
      end

      create(:supplement_tag_filter,
             tag: ActsAsTaggableOn::Tag.find_by(name: old_tag),
             new_tag: create(:tag, name: new_tag),
             hub: @hub, scope: @feed_item)
    end

    def filter_list
      @feed_item.tag_filters
    end

    def setup_other_items_tags(filter, item)
      filter = create(:add_tag_filter, tag: filter.tag, hub: @hub,
                                       scope: item)
      filter.apply
    end

    context 'user owns a hub with a feed and items' do
      include_context 'user owns a hub with a feed and items'

      it 'supplements tags' do
        @feed_item = @feed_items.order(:id).first
        old_tag = 'just-a-tag'
        new_tag = 'not-just-a-tag'

        filer_old = new_add_filter(old_tag)
        filer_old.apply

        filter = add_filter(old_tag, new_tag)
        filter.apply

        new_tag_lists = tag_lists_for(@feed_item, @hub.tagging_key)
        expect(new_tag_lists).to show_effects_of filter
      end
    end

    it_behaves_like 'an item-level tag filter'
  end
end
