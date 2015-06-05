describe AddTagFilter, '#apply' do
  include_context 'user owns a hub with a feed and items'

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

describe AddTagFilter, '#rollback' do
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
