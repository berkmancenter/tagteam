# frozen_string_literal: true
FactoryGirl.define do
  sequence :tag_name do |n|
    "test-tag-#{n}"
  end
end
