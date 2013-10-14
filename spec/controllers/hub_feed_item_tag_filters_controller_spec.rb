require 'spec_helper'

describe HubFeedItemTagFiltersController do
  include Devise::TestHelpers
  context "create" do
    before do
      @user = User.first
      sign_in @user
    end

    context "when creating a new tag" do

      before do 
        @hub = Hub.first
        @feed_item = FeedItem.first
        get :create, {
          "filter_type"=>"AddTagFilter",
          "new_tag"=>"testing456",
          "hub_id"=> @hub.id,
          "feed_item_id"=>@feed_item.id,
          "format" => "html"
        } 
      end
    
      it "creates an AddTagFilter record" do
        t = ActsAsTaggableOn::Tag.find_by_name "testing456"
        af = AddTagFilter.find_by_tag_id t.id

        af.should_not be_nil
        assigns[:hub_feed_item_tag_filter].filter.should == af
      end

      it "responds with at positive message"  do
        flash[:notice].should == "Added that filter to this hub."
      end

      it "gives the user ownership of that tag" do
        users_tags = @user.owned_tags.pluck(:name)
        users_tags.should include "testing456"
      end
      


    end

    context "when deleting a tag" do
    end

    
    context "when modifying a tag" do
    end
  end
end
