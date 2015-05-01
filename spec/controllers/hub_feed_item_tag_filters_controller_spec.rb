require 'rails_helper'

RSpec.describe HubFeedItemTagFiltersController, type: :controller do
  context "create" do
    before do
      @user = User.first
      sign_in @user
    end

    context "when creating a new tag" do

      before do 
        @hub = Hub.first
        @feed_item = FeedItem.first
        @feed_item.skip_tag_indexing_after_save = true
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

      it "responds with a positive message"  do
        flash[:notice].should == "Added that filter to this hub."
      end

      it "gives the user ownership of that tag" do
        users_tags = @user.owned_tags.pluck(:name)
        users_tags.should include "testing456"
      end
    end

    context "when deleting a tag" do
      before do 
        @hub = Hub.first
        @feed_item = FeedItem.first
        @feed_item.skip_tag_indexing_after_save = true

        @tag = ActsAsTaggableOn::Tag.create(:name => "testing123")
        @user.tag @feed_item, :with => "testing123", :on => "hub_#{@hub.id}"

        post :create, {
          "filter_type"=>"DeleteTagFilter",
          "new_tag"=>"", 
          "modify_tag"=>"",
          "feed_item_id" => @feed_item.id,
          "hub_id" => @hub.id,
          "tag_id" => @tag.id
        }
      end

      it "creates a DeleteTagFilter record" do
        df = DeleteTagFilter.find_by_tag_id @tag.id
        df.should_not be_nil
        assigns[:hub_feed_item_tag_filter].filter.should == df
      end

      it "response with a positive message" do
        flash[:notice].should == "Added that filter to this hub."
      end

      it "removes the tag from the users owned tags" do
        users_tags = @user.owned_tags.pluck(:name)
        users_tags.should_not include "testing123"
      end
    end

    
    context "when modifying a tag" do
      before do 
        @hub = Hub.first
        @feed_item = FeedItem.first
        @feed_item.skip_tag_indexing_after_save = true

        @tag = ActsAsTaggableOn::Tag.create(:name => "testing123")
        @user.tag @feed_item, :with => "testing123", :on => "hub_#{@hub.id}"

        post :create, {
          "filter_type"=>"ModifyTagFilter",
          "new_tag"=>"testing456", 
          "feed_item_id" => @feed_item.id,
          "hub_id" => @hub.id,
          "tag_id" => @tag.id
        }
      end

      it "creates a ModifyTagFilter record" do
        mf = ModifyTagFilter.find_by_tag_id @tag.id
        mf.tag_id.should == @tag.id
        assigns[:hub_feed_item_tag_filter].filter.should == mf
      end

      it "responds with a positive message" do
        flash[:notice].should == "Added that filter to this hub."
      end

      it "modifies the users owned tags" do
        users_tags = @user.owned_tags.pluck(:name)
        users_tags.should_not include "testing123"
        users_tags.should include "testing456"
      end
    end
  end
end
