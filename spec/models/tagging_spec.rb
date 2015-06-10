require 'rails_helper'

describe ActsAsTaggableOn::Tagging do
  context "Tagging was created by a bookmarker" do
    it "is owned by the bookmarker"
  end

  context "Tagging was created by an import process" do
    it "is owned by something..."
  end

  describe '#deactivate' do
    it 'copies itself into the deactivated_taggings table' do
      tagging = create(:tagging)
      tagging.deactivate
      # We have to remove created_at for some weird reason. It's truncating off
      # the nanoseconds of the time object when it's copying over.
      expect(DeactivatedTagging.first.attributes.delete(:created_at)).
        to be == tagging.attributes.delete(:created_at)
    end

    it 'removes itself from the taggings table' do
      tagging = create(:tagging)
      tagging.deactivate
      expect(ActsAsTaggableOn::Tagging.count).to eq(0)
    end

    it 'returns the deactivated copy of itself' do
      tagging = create(:tagging)
      deactivated = tagging.deactivate
      expect(deactivated).to have_attributes(tagging.attributes)
    end
  end
end
