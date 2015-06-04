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
      # If this filter is in the middle of a chain and gets deleted
    end
  end
end
