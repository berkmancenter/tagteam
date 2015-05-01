require 'rails_helper'

describe HubTagFiltersController do
  context "#create" do
    before do
      @user = User.first
      @hub = Hub.first
      @user.has_role!(:owner, @hub)
      @user.has_role!(:creator, @hub)
      sign_in @user
    end

    
    context "when creating a new tag" do
      before do 
        post :create, {
          "filter_type"=>"AddTagFilter",
          "tag_id" => "",
          "new_tag"=>"testing456",
          "hub_id"=> @hub.id,
          "format" => "html"
        } 
      end


      it "creates an AddTagFilter" do
        t = ActsAsTaggableOn::Tag.find_by_name "testing456"
        af = AddTagFilter.find_by_tag_id t.id
        af.should_not be_nil
        assigns[:hub_tag_filter].filter.should == af
      end

      it "responds with a proper flash message" do
        flash[:notice].should == "Added that filter to this hub."
      end

      it "adds the user as an owner of the tag" do
        users_tags = @user.owned_tags.pluck(:name)
        users_tags.should include "testing456"
      end

    end

    context "when deleting a tag" do
      before do 
        @hub_feed = @hub.hub_feeds.first
        @feed_item = @hub_feed.feed_items.first
        @feed_item.skip_tag_indexing_after_save = true

        @tag = ActsAsTaggableOn::Tag.create(:name => "testing123")
        @user.tag @feed_item, :with => "testing123", :on => "hub_#{@hub.id}"

        post :create, {
          "filter_type"=>"DeleteTagFilter",
          "new_tag"=>"testing123", 
          "hub_id" => @hub.id,
        }
      end

      it "creates a DeleteTagFilter record" do
        df = DeleteTagFilter.find_by_tag_id @tag.id
        df.should_not be_nil
        assigns[:hub_tag_filter].filter.should == df
      end

      it "response with a positive message" do
        flash[:notice].should == "Added that filter to this hub."
      end

      it "removes the tag from the users owned tags" do
        users_tags = @user.owned_tags.pluck(:name)
        users_tags.should_not include "testing123"
      end
    end



    context "when modifying an existing tag" do
      before do 
        @hub_feed = @hub.hub_feeds.first
        @feed_item = @hub_feed.feed_items.first
        @feed_item.skip_tag_indexing_after_save = true

        @tag = ActsAsTaggableOn::Tag.create(:name => "testing123")
        @user.tag @feed_item, :with => "testing123", :on => "hub_#{@hub.id}"

        post :create, {
          "filter_type"=>"ModifyTagFilter",
          "new_tag"=>"testing456", 
          "modify_tag" => "testing123",
          "hub_id" => @hub.id,
        }
      end

      it "creates a ModifyTagFilter record" do
        mf = ModifyTagFilter.find_by_tag_id @tag.id
        mf.tag_id.should == @tag.id
        assigns[:hub_tag_filter].filter.should == mf
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
