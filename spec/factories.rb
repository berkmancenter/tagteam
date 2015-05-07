def set_roles(object, evaluator)
  evaluator.owner.has_role!(:owner, object)
  evaluator.owner.has_role!(:creator, object)
end

FactoryGirl.define do
  sequence :tag_name, aliases: [:new_tag_name] do |n|
    "test-tag-#{n}"
  end

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
      after(:create) { |hub, evaluator|
        set_roles(hub, evaluator)
        hub.feeds.each { |feed| set_roles(feed, evaluator) }
      }
    end
  end

  factory :feed do
    before(:create) { VCR.insert_cassette('feed_factory') }
    after(:create) { VCR.eject_cassette }

    feed_url 'http://reagle.org/joseph/blog/?flav=atom'
  end

  factory :tag, class: ActsAsTaggableOn::Tag do
    name { generate(:tag_name) }
  end

  trait :tag_filter do
    tag { association(:tag, name: tag_name) }
    transient { tag_name }
  end

  factory :add_tag_filter, traits: [:tag_filter]
  factory :delete_tag_filter, traits: [:tag_filter]
  factory :modify_tag_filter do
    tag_filter
    new_tag { association(:tag, name: new_tag_name) }
    transient { new_tag_name }
  end

  factory :hub_tag_filter, class: HubTagFilter do
    hub
    filter do
      filter_class = "#{type}_tag_filter".to_sym
      if type == :modify
        association(filter_class, tag: tag, new_tag_name: new_tag_name)
      else
        association(filter_class, tag_name: tag_name)
      end
    end

    transient do
      tag_name
      new_tag_name
      tag { build(:tag) }
      type :add
    end

    trait :owned do
      transient do
        owner create(:user)
      end
      after(:create) { |filter, evaluator| set_roles(filter, evaluator) }
    end
  end
end
