def set_roles(object, evaluator)
  evaluator.owner.has_role!(:owner, object)
  evaluator.owner.has_role!(:creator, object)
end

FactoryGirl.define do
  factory :user do
    sequence(:username) { |n| "jdcc#{n}" }
    sequence(:email) { |n| "jclark+#{n}@cyber.law.harvard.edu" }
    password 'password'
    password_confirmation 'password'

    factory :confirmed_user do
      after(:create) { |user| user.confirm! }
    end
  end


  factory :hub do
    title 'My hub'

    trait :with_feed do
      after(:create) do |hub|
        hub.feeds << create(:feed)
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

  factory :feed do
    feed_url 'http://reagle.org/joseph/blog/?flav=atom'
  end
end
