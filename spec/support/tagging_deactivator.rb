shared_examples 'a tagging deactivator' do
  describe '#deactivate_tagging' do
    it 'copies the tagging into the deactivated_taggings table' do
      tagging = create(:tagging)
      deactivate_tagging(tagging)
      # We have to remove created_at for some weird reason. It's truncating off
      # the nanoseconds of the time object when it's copying over.
      expect(DeactivatedTagging.first.attributes.delete(:created_at)).
        to be == tagging.attributes.delete(:created_at)
    end

    it 'removes the tagging from the taggings table' do
      tagging = create(:tagging)
      tagging.deactivate
      expect(ActsAsTaggableOn::Tagging.count).to eq(0)
    end

    it 'returns the deactivated copy of the tagging' do
      tagging = create(:tagging)
      deactivated = tagging.deactivate
      expect(deactivated).to have_attributes(tagging.attributes)
    end
  end
end
