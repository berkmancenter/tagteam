require 'rails_helper'

shared_examples "an item-level tag filter" do |filter_type|
  context "other items exist" do
    it "doesn't affect other items", wip: true do
    end
  end
end

describe AddTagFilter, "scoped to an item", wip: true do
  def add_filter(tag_name = 'add-test')
    new_tag = create(:tag, name: tag_name)
    filter = create(:hub_tag_filter, action: :add, tag: new_tag)
    @hub.hub_tag_filters << filter
    filter
  end

  def filter_list
    @hub.hub_tag_filters
  end

  context "user owns a hub with a feed and items" do
    include_context "user owns a hub with a feed and items"

    it "adds tags" do
      new_tag = 'add-test'
      filter = add_filter(new_tag)
      tag_lists = tag_lists_for(@feed_items, @hub.tagging_key)
      expect(tag_lists).to show_effects_of filter
    end
  end

  it_behaves_like "a tag filter", :add
  it_behaves_like "a hub-level tag filter"
end

describe ModifyTagFilter, "scoped to an item", wip: true do
  def add_filter(old_tag = 'social', new_tag = 'not-social')
    filter = create(
      :hub_tag_filter,
      action: :modify,
      tag: ActsAsTaggableOn::Tag.find_by_name(old_tag),
      new_tag: create(:tag, name: new_tag)
    )
    @hub.hub_tag_filters << filter
    filter
  end

  def filter_list
    @hub.hub_tag_filters
  end

  context "user owns a hub with a feed and items" do
    include_context "user owns a hub with a feed and items"

    it "modifies tags" do
      old_tag = 'social'
      new_tag = 'not-social'

      filter = add_filter(old_tag, new_tag)
      new_tag_lists = tag_lists_for(@feed_items.reload, @hub.tagging_key, true)

      expect(new_tag_lists).to show_effects_of filter
    end

  end

  it_behaves_like "a tag filter", :modify
  it_behaves_like "a hub-level tag filter"
end

describe DeleteTagFilter, "scoped to an item", wip: true do
  def add_filter(old_tag = 'social')
    filter = create(:hub_tag_filter, action: :delete,
                    tag: ActsAsTaggableOn::Tag.find_by_name(old_tag))
    @hub.hub_tag_filters << filter
    filter
  end

  def filter_list
    @hub.hub_tag_filters
  end

  context "user owns a hub with a feed and items" do
    include_context "user owns a hub with a feed and items"

    it "removes tags" do
      deleted_tag = 'social'

      filter = add_filter(deleted_tag)

      tag_lists = tag_lists_for(@feed_items, @hub.tagging_key)
      expect(tag_lists).to show_effects_of filter
    end

  end

  it_behaves_like "a tag filter", :delete
  it_behaves_like "a hub-level tag filter"
end
