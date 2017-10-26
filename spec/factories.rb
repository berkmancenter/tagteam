# frozen_string_literal: true

FactoryBot.define do
  sequence :tag_name do |n|
    "test-tag-#{n}"
  end
end
