require 'rails_helper'

describe FeedItem do
  describe '#copy_global_tags_to_hubs' do
    context 'a feed item with tag "a" exists in two hubs' do
      before(:each) do
        @hub1 = create(:hub)
        @hub2 = create(:hub)
        @feed = create(:feed)
        @tag = create(:tag, name: 'a')
        @hub1.feeds << @feed
        @hub2.feeds << @feed
      end

      def tags_in_context(feed_item, context)
        feed_item.taggings.
          where(context: context).
          map{ |tagging| [tagging.tag_id, tagging.taggable, tagging.tagger] }
      end

      it 'copies all taggings into each hub' do
        feed_item = create(:feed_item_from_feed, :tagged, tag: @tag, feed: @feed)

        original_taggings = tags_in_context(feed_item, 'tags')
        copied_taggings1 = tags_in_context(feed_item, @hub1.tagging_key)
        copied_taggings2 = tags_in_context(feed_item, @hub2.tagging_key)

        expect(original_taggings.count).to be > 0
        expect(original_taggings).to match_array(copied_taggings1)
        expect(original_taggings).to match_array(copied_taggings2)
      end

      it 'does not create duplicate taggings' do
        feed_item = create(:feed_item_from_feed, :tagged, tag: @tag, feed: @feed)
        expect{
          feed_item.copy_global_tags_to_hubs
        }.not_to raise_error
      end
    end
  end
end
