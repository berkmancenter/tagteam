# frozen_string_literal: true
FactoryGirl.define do
  factory :hub do
    title 'My hub'

    trait :with_feed do
      transient do
        with_feed_url 0
      end
      after(:create) do |hub, evaluator|
        hub.feeds << create(:feed, with_url: evaluator.with_feed_url)
      end
    end

    trait :owned do
      transient do
        owner create(:user)
      end
      after(:create) do |hub, evaluator|
        set_roles(hub, evaluator)
        hub.feeds.each { |feed| set_roles(feed, evaluator) }
      end
    end
  end
end
