# frozen_string_literal: true

FactoryGirl.define do
  factory :hub_user_notification do
    user
    hub
    notify_about_modifications false
  end
end
