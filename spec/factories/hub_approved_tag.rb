# frozen_string_literal: true
FactoryGirl.define do
  factory :hub_approved_tag, class: HubApprovedTag do
    hub
    tag { generate(:tag_name) }
  end
end
