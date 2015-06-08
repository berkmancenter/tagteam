require 'rails_helper'

describe AddTagFilter do
  include_examples TagFilter

  describe '#apply' do
    context 'the filter is scoped to a hub' do
      context 'the filter adds tag "a"' do
        before(:each) do
          @hub = create(:hub)
          @tag = create(:tag, name: 'a')
          @filter = create(:add_tag_filter, tag: @tag, scope: @hub)
        end

        it 'adds the tag "a" to all items in the hub' do
          expect(tag_lists_for(@hub.feed_items, @hub.tagging_key)).
            to show_effects_of @filter
        end

        it 'owns all the taggings it creates'
        it 'can apply taggings to only a few items in its scope'

        context 'active taggings already exist between tag "a" and items' do
          it 'deactivates all tag "a" taggings'
          it 'does not deactivate irrelevant taggings'
        end
      end
    end
  end

  describe '#rollback' do
    it 'deletes any owned taggings'
    it 'reactivates deactived taggings'

    context 'a newer filter exists that deactivates some taggings' do
      it 'does not reactivate taggings it should not' do
        # Some items come in from the external feed with 'tag1'
        # We add a hub filter that adds 'tag1' to all feed items
        # We add a feed filter that adds 'tag1' to all feed items
        # We rollback the hub filter
        # It shouldn't reactivate external feed taggings for items affected
        # by the feed filter
        #
        # We add a hub filter that adds 'tag1' to all items
        # We add a modify filter that changes 'tag1' to 'tag2'
        # We rollback the add filter
      end
    end
  end

  describe '#description' do
    it 'returns "Add"' do
      expect(create(:add_tag_filter).description).to eq('Add')
    end
  end

  describe '#deactivates_taggings' do
    context 'the filter is scoped to a hub' do
      context 'the filter adds tag "a"' do
        before(:each) do
          @tag = create(:tag, name: 'a')
          @filter = create(:add_tag_filter, tag: @tag, scope: create(:hub))
        end

        context 'no feed items exist' do
          it 'returns nothing' do
            expect(@filter.deactivates_taggings).to be_empty
          end
        end

        context 'a feed item exists with tag "a"' do
          before(:each) do
            @feed_item = create(:feed_item, :tagged, tag: 'a')
          end
          it 'returns the tagging attaching tag "a" to that feed item' do
            expect(@filter.deactivates_taggings).
              to match_array(@feed_item.taggings)
          end
        end

        context 'a feed item exists with tag "b"' do
          before(:each) do
            @feed_item = create(:feed_item, :tagged, tag: 'b')
          end
          it 'returns nothing' do
            expect(@filter.deactivates_taggings).to be_empty
          end
        end
      end
    end
  end

  describe '#reactivates_taggings' do
    it 'reactivates the appropriate taggings'
  end
end
