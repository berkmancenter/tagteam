require 'rails_helper'

#describe ActsAsTaggableOn::Tagging, wip: true do
#  it "connects tags to items" do
#  end
#
#  context "Tagging was created by an external feed" do
#    it "is owned by the feed" do
#    end
#    
#    it "adds tags in all hubs" do
#    end
#  end
#
#  context "Tagging was created by a filter" do
#    it "is owned by the filter creator" do
#    end
#
#    it "only adds tags in the filter's hub" do
#    end
#  end
#
#  context "Tagging was created by a bookmarker" do
#    it "is owned by the bookmarker" do
#    end
#
#    it "only adds tags in the filter's hub" do
#    end
#  end
#
#  context "Tagging was created by an import process", wip: true do
#  end
#end

describe ActsAsTaggableOn::Tagging, '#deactivate' do
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
