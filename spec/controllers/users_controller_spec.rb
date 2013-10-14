require 'spec_helper'


describe UsersController do
  
  context "tags" do

    it "gets the users tags" do
      hub = Hub.first
      feed_item = FeedItem.first
      user = User.first

      user.tag feed_item, :with => "test", :on => :user_tags

      hub = Hub.find 1
      discover_params = "http://test.host/hubs/1/user/1/rss"
      
      get :tags, :hub_id => 1, :username => "jdcc"
      assigns[:hub].should == hub
      assigns[:user].should == user
      assigns[:show_auto_discovery_params].should == discover_params
      assigns[:feed_items].first.taggable.should == feed_item

    end

  end


end
