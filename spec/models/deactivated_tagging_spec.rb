# frozen_string_literal: true
require 'rails_helper'

RSpec.describe DeactivatedTagging, type: :model do
  describe '#reactivate' do
    let(:delete_tag_filter) { create(:delete_tag_filter) }
    let(:tagging) { create(:tagging) }
    let(:reactivated_tagging) { @deactivated_tagging.reactivate }

    before do
      @deactivated_tagging = delete_tag_filter.deactivate_tagging(tagging)
    end

    it 'copies itself into the taggings table' do
      expect { reactivated_tagging }.to change { ActsAsTaggableOn::Tagging.count }.by(1)
    end

    it 'removes itself from the deactivated taggings table' do
      expect { reactivated_tagging }.to change { described_class.count }.by(-1)
    end

    it 'returns the reactivated copy of itself' do
      expect(reactivated_tagging).to eq(tagging)
    end
  end
end
