# frozen_string_literal: true
FactoryGirl.define do
  factory :documentation do
    sequence(:match_key) { |n| "match-key-#{n}" }
    title 'MyTitle'
  end
end
