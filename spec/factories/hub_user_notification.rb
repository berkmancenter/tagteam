# frozen_string_literal: true
FactoryGirl.define do
  factory :hub_user_notification, class: HubUserNotification do
    hub
    user
    notify_about_modifications { true }
  end
end
