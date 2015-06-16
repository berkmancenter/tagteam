require 'rails_helper'

describe DeactivatedTagging do
  describe '#reactivate' do
    it 'copies itself into the taggings table' do
      tagging = create(:tagging)
      create(:delete_tag_filter).deactivate_tagging(tagging)
      expect(ActsAsTaggableOn::Tagging.count).to eq(0)

      d_tagging = DeactivatedTagging.first
      d_tagging.reactivate
      expect(ActsAsTaggableOn::Tagging.first).to eq(tagging)
    end

    it 'removes itself from the deactivated taggings table' do
      tagging = create(:tagging)
      create(:delete_tag_filter).deactivate_tagging(tagging)
      expect(ActsAsTaggableOn::Tagging.count).to eq(0)

      d_tagging = DeactivatedTagging.first
      d_tagging.reactivate

      expect(DeactivatedTagging.count).to eq(0)
    end

    it 'returns the reactivated copy of itself' do
      tagging = create(:tagging)
      create(:delete_tag_filter).deactivate_tagging(tagging)
      expect(ActsAsTaggableOn::Tagging.count).to eq(0)

      d_tagging = DeactivatedTagging.first
      new_tagging = d_tagging.reactivate

      expect(new_tagging).to eq(tagging)
    end
  end
end
