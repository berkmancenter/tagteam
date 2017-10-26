# frozen_string_literal: true

FactoryBot.define do
  factory :republished_feed do
    title 'MyString'
    sequence(:url_key) { |n| "urlkey#{n}" }
  end
end
