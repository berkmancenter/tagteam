# frozen_string_literal: true
require 'rails_helper'

RSpec.describe HubUserNotification, type: :model do
  it 'belongs to hub and user' do
    @user = create(:user)
    @hub = create(:hub)
    @hub_user_notification = create(
      :hub_user_notification,
      hub: @hub,
      user: @user
    )

    expect(@hub_user_notification).to  belong_to(:hub)
    expect(@hub_user_notification).to  belong_to(:user)
  end
end
