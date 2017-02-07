# frozen_string_literal: true
require 'rails_helper'

RSpec.feature 'Feed-level tag filtering', broken: true do
  before do
    # @user = create(:confirmed_user)
    # @hub = create(:hub, :with_feed, :owned, with_feed_url: 1, owner: @user)
    # @hub_feed = @hub.hub_feeds.first
    # visit new_user_session_path

    # within('#new_user') do
    # fill_in 'Username or email', with: @user.username
    # fill_in 'Password', with: 'password'

    # click_on 'Sign in'
    # end
  end

  scenario 'adding a modify feed-level filter', wip: true, js: true, broken: true do
    visit hub_feed_tags_path(@hub_feed)

    click_link 'claire mccarthy'
    within('.tag_filter.modify') do
      click_on 'all items in this feed'
    end

    fill_in 'new_tag_for_filter', with: 'claire mccarthy md'

    click_link 'Submit'
  end

  scenario 'removing a feed-level filter' do
    pending('Not yet implemented')
  end
end
