# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TagFiltersController, type: :controller do
  let(:hub) { create(:hub, :owned) }
  let(:other_user) { create(:confirmed_user) }
  let(:tag_filter) { create(:tag_filter, scope: hub, hub: hub) }
  let(:feed_item) { create(:feed_item_from_feed) }

  it 'does not allow #destroy with out user signed_in' do
    delete :destroy, params: { hub_id: hub.id, id: tag_filter.id }

    expect(flash[:alert]).to eq 'You need to sign in or sign up before continuing.'
    expect(response).to redirect_to(new_user_session_path)
  end

  it 'hub owner should destroy the hub wide filter' do
    stub_sign_in hub.owners.first

    delete :destroy, params: { hub_id: hub.id, id: tag_filter.id }
    expect(flash[:notice]).to eq 'Deleting that tag filter.'
    expect(response).to redirect_to(hub_tag_filters_path(hub))
  end

  it 'other user should not destroy the hub wide filter' do
    stub_sign_in other_user

    delete :destroy, params: { hub_id: hub.id, id: tag_filter.id }
    expect(flash[:alert]).to eq 'You can\'t access that - sorry!'
    expect(response).to redirect_to(root_path)
  end

  it 'user should delete the feed_item level filter' do
    stub_sign_in hub.owners.first
    item_level_tag_filter = create(:tag_filter, scope: feed_item, hub: hub)

    delete :destroy, params: { hub_id: hub.id, feed_item_id: feed_item.id, id: item_level_tag_filter.id, format: :js }

    expect(flash[:notice]).to eq 'Deleted that tag filter.'
    expect(response).to redirect_to(hub_feed_item_tag_filters_path(hub.id, feed_item.id))
  end
end
