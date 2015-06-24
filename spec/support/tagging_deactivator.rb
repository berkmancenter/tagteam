shared_examples 'a tagging deactivator' do |filter_type|
  describe '#deactivate_tagging' do
    it 'copies the tagging into the deactivated_taggings table' do
      filter = create(filter_type)
      tagging = create(:tagging)
      filter.deactivate_tagging(tagging)
      # We have to remove created_at for some weird reason. It's truncating off
      # the nanoseconds of the time object when it's copying over.
      expect(DeactivatedTagging.count).to eq(1)
      expect(DeactivatedTagging.first.attributes.delete(:created_at)).
        to be == tagging.attributes.delete(:created_at)
    end

    it 'removes the tagging from the taggings table' do
      filter = create(filter_type)
      tagging = create(:tagging)
      filter.deactivate_tagging(tagging)
      expect(ActsAsTaggableOn::Tagging.count).to eq(0)
    end

    it 'returns the deactivated copy of the tagging' do
      filter = create(filter_type)
      tagging = create(:tagging)
      deactivated = filter.deactivate_tagging(tagging)
      expect(deactivated).to have_attributes(tagging.attributes)
    end
  end

  describe '#self_deactivated_taggings', wip: true do
    it 'returns all deactivated taggings deactivated by this deactivator' do
      filter = create(filter_type)
      tagging = create(:tagging)
      filter.deactivate_tagging(tagging)
      expect(filter.self_deactivated_taggings.count).to eq(1)
    end
  end
end
