# frozen_string_literal: true
require 'rails_helper'

RSpec.describe DeactivatedTagging, type: :model do
  describe '#reactivate' do
    it 'copies itself into the taggings table' do
      tagging = create(:tagging)
      create(:delete_tag_filter).deactivate_tagging(tagging)
      expect(ActsAsTaggableOn::Tagging.count).to eq(0)

      d_tagging = described_class.first
      d_tagging.reactivate
      expect(ActsAsTaggableOn::Tagging.first).to eq(tagging)
    end

    it 'removes itself from the deactivated taggings table' do
      tagging = create(:tagging)
      create(:delete_tag_filter).deactivate_tagging(tagging)
      expect(ActsAsTaggableOn::Tagging.count).to eq(0)

      d_tagging = described_class.first
      d_tagging.reactivate

      expect(described_class.count).to eq(0)
    end

    it 'returns the reactivated copy of itself' do
      tagging = create(:tagging)
      create(:delete_tag_filter).deactivate_tagging(tagging)
      expect(ActsAsTaggableOn::Tagging.count).to eq(0)

      d_tagging = described_class.first
      new_tagging = d_tagging.reactivate

      expect(new_tagging).to eq(tagging)
    end
  end
end
