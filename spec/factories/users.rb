# frozen_string_literal: true
FactoryGirl.define do
  factory :user do
    sequence(:username) { |n| "jdcc#{n}" }
    sequence(:email) { |n| "jclark+#{n}@cyber.law.harvard.edu" }
    password 'password'
    password_confirmation 'password'

    factory :confirmed_user do
      after(:create, &:confirm)
    end
  end
end
