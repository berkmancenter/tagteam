describe AddTagFilter do
  include_examples TagFilter
end

describe AddTagFilter, '#apply', wip: true do
  it 'adds the given tag to all items in scope' do
  end

  it 'owns all taggings it creates' do
  end

  context 'active taggings exist between given tag and items in scope' do
    it 'deactivates relevant taggings' do
    end

    it 'does not deactivate irrelevant taggings' do
    end
  end
end

describe AddTagFilter, '#rollback', wip: true do
  it 'deletes any owned taggings' do
  end

  it 'reactivates deactived taggings' do
  end

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

describe AddTagFilter, '#description' do
  it 'returns "Add"' do
    expect(create(:add_tag_filter).description).to eq('Add')
  end
end

describe '#deactivates_taggings' do
  context 'the filter is scoped to a hub' do
    context 'the filter adds tag "a"' do
      before(:all) do
        @filter = create(
          :add_tag_filter, tag: create(:tag, name: 'a'), scope: create(:hub))
      end

      context 'no feed items exist' do
        it 'returns nothing' do
          expect(@filter.deactivates_taggings).to be_empty
        end
      end

      context 'a feed item exists with tag "a"' do
        before(:all) do
          @feed_item = create(:feed_item, :tagged, tag: 'a')
        end
        it 'returns the tagging attaching tag "a" to that feed item' do
          expect(@filter.deactivates_taggings).to match_array(@feed_item.taggings)
        end
      end

      context 'a feed item exists with tag "b"' do
        before(:all) do
          @feed_item = create(:feed_item, :tagged, tag: 'b')
        end
        it 'returns nothing' do
          expect(@filter.deactivates_taggings).to be_empty
        end
      end
    end
  end
end

describe '#reactivates_taggings', wip: true do
end
