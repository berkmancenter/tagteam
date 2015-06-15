require 'rails_helper'

describe "Tag filter interactions" do
  context "a user owns a hub with a feed and items" do
    include_context 'user owns a hub with a feed and items'
    context "an item-level filter adds tag 'A' an item" do
      before(:each) do
        @tagA = create(:tag, name: 'A')
        @item = @feed_items.first
        @item_filter = create(:add_tag_filter, tag: @tagA,
                              hub: @hub, scope: @item)
        @item_filter.apply
      end
      context "a feed-level filter changes tag 'A' to tag 'B'" do
        before(:each) do
          @tagB = create(:tag, name: 'B')
          @feed_filter = create(:modify_tag_filter, tag: @tagA, new_tag: @tagB,
                                scope: @hub_feed, hub: @hub)
          @feed_filter.apply
        end
        context "a hub-level filter removes all 'A' tags" do
          before(:each) do
            @hub_filter = create(:delete_tag_filter, tag: @tagA,
                                 hub: @hub, scope: @hub)
            @hub_filter.apply
          end
          scenario "the hub-level filter is rolled back", wip: true do
            @hub_filter.rollback
            expect(@item.all_tags_list_on(@hub.tagging_key)).to not_contain 'A'
          end
        end
      end
    end
  end
end
