# frozen_string_literal: true
FactoryGirl.define do
  factory :user do
    sequence(:username) { |n| "jdcc#{n}" }
    sequence(:email) { |n| "jclark+#{n}@cyber.law.harvard.edu" }
    password 'password'
    password_confirmation 'password'
    approved true
    signup_reason 'MyString'

    factory :confirmed_user do
      after(:create, &:confirm)
    end

    trait :superadmin do
      after(:create) { |user| user.has_role!(:superadmin) }
    end

    trait :documentation_admin do
      after(:create) { |user| user.has_role!(:documentation_admin) }
    end
  end
end
