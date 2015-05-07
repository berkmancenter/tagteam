require 'rails_helper'

RSpec::Matchers.define_negated_matcher :not_contain, :include

shared_context "User owns a hub with a feed and items" do
  before(:each) do
    @user = create(:confirmed_user)
    @hub = create(:hub, :with_feed, :owned, owner: @user)
  end
end

shared_examples "a tag filter" do |filter_type|
  include_context "User owns a hub with a feed and items"

  context "The filter exists" do
    before(:each) do
      @filter = create(:hub_tag_filter, type: filter_type, hub: @hub, tag_name: 'shared-test')
    end

    it "rolls back its changes when removed", wip: true do
    end

    it "regains precedence when renewed", wip: true do
    end

    it "loses precedence to more recent filters", wip: true do
    end

    it "cannot be duplicated in a hub", wip: true do
    end

    context "other hubs exist and filter is scoped to a hub" do
      it "doesn't affect other hubs", wip: true do
      end
    end

    context "other feeds exist and filter is scoped to a feed" do
      it "doesn't affect other feeds", wip: true do
      end
    end

    context "other items exists and filter is scoped to an item" do
      it "doesn't affect other items", wip: true do
      end
    end
  end

  it "cannot conflict with other filters in a scope", wip: true do
  end

  context "A hub-level filter exists that adds a tag" do
    before(:each) do
    end

    it "takes precedence over the existing filter", wip: true do
    end
  end
end

describe AddTagFilter do
  it_behaves_like "a tag filter", :add
  include_context "User owns a hub with a feed and items"

  it "adds tags" do
    @hub.hub_tag_filters << create(:hub_tag_filter, type: :add, tag_name: 'add-test')
    feed_items = @hub.hub_feeds.first.feed_items
    tag_lists = tag_lists_for(feed_items, @hub.tagging_key)
    expect(tag_lists).to all( include 'add-test' )
  end
end

describe ModifyTagFilter do
  it_behaves_like "a tag filter", ModifyTagFilter
  include_context "User owns a hub with a feed and items"

  it "modifies tags" do
    old_tag = ActsAsTaggableOn::Tag.find_by_name('social')
    new_tag_name = 'not-social'
    feed_items = @hub.hub_feeds.first.feed_items
    old_tag_lists = tag_lists_for(feed_items, @hub.tagging_key)

    @hub.hub_tag_filters << create(:hub_tag_filter, type: :modify,
                                   tag: old_tag, new_tag_name: new_tag_name)

    new_tag_lists = tag_lists_for(feed_items.reload, @hub.tagging_key)
    correct_tag_lists = old_tag_lists.map do |list|
      list.map{ |tag| tag == old_tag.name ? new_tag_name : tag }
    end
    expect(new_tag_lists).to eq correct_tag_lists
  end
end

describe DeleteTagFilter do
  it_behaves_like "a tag filter", DeleteTagFilter
  include_context "User owns a hub with a feed and items"

  it "removes tags", wip: true do
  end
end
