require 'rails_helper'

feature "Hub input feed management" do
  context "User owns a hub", :vcr => { :cassette_name => "feed_factory_reagle_org" } do

    before(:each) do
      @user = create(:confirmed_user)
      @hub = create(:hub, :owned, owner: @user)
      
      visit new_user_session_path
      fill_in "Username or email", with: @user.username
      fill_in "Password", with: @user.password
      click_button "Sign in"
    end

    scenario "User adds an input feed" do
      # For unknown reasons there is a problem adding the feed
      @feed = build(:feed)
      visit hub_hub_feeds_path @hub
      fill_in "New input feed", with: @feed.feed_url
      click_button "Add"

      expect(page).to have_text 'Added that feed'

      visit items_hub_path @hub
      expect(page).to have_css '.feed-item', count: 10
      expect(page).to have_css 'a.tag'
    end

    context "User's hub has input feed" do
      before(:each) do
        @hub = create(:hub, :owned, :with_feed, owner: @user)
      end

      scenario "User removes an input feed", wip: true do
        pending("Not yet implemented")
        # items do not get removed
        visit items_hub_path @hub
        expect(page).to have_css '.feed-item', count: 10

        visit hub_hub_feeds_path @hub
        click_link "Feed actions"
        click_link "Remove from hub"

        visit items_hub_path @hub
        expect(page).to have_css '.feed-item', count: 10

        # taggings with feed as owner get put where? still need a global context
        # feed still exists, but isn't updated and doesn't show in any hubs?
      end
    end

    context "Multiple hubs exist with same input feeds" do
      scenario "User looks at the tags in each hub" do
      end
    end
  end
end
