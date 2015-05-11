def set_roles(object, evaluator)
  evaluator.owner.has_role!(:owner, object)
  evaluator.owner.has_role!(:creator, object)
end

def filter_association(action, tag, new_tag = nil)
  filter_class = "#{action}_tag_filter".to_sym
  if :modify == action
    association(filter_class, tag: tag, new_tag: new_tag)
  else
    association(filter_class, tag: tag)
  end
end

FactoryGirl.define do
  sequence :tag_name do |n|
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

  factory :hub_feed do
    hub
    feed
  end

  factory :feed_item do
    title 'Test Title'
    sequence(:url) { |n| "http://example.com/?tag=#{n}" }
  end

  factory :feed do
    before(:create) { |feed| VCR.insert_cassette("feed_factory-#{feed.feed_url}") }
    after(:create) { VCR.eject_cassette }

    sequence(:feed_url) do |n|
      feeds = [
       'http://reagle.org/joseph/blog/?flav=atom',
       'http://childrenshospitalblog.org/category/claire-mccarthy-md/feed/',
       'http://feeds.feedburner.com/mfeldstein/feed/',
      ]
      feeds[n - 1]
    end
  end

  factory :tag, class: ActsAsTaggableOn::Tag do
    name { generate(:tag_name) }
  end

  factory :add_tag_filter do
    tag
  end
  factory :delete_tag_filter do
    tag
  end
  factory :modify_tag_filter do
    tag
    association :new_tag, factory: :tag
  end

  trait :filter_transients do
    transient do
      action :add
      tag { create(:tag) }
      new_tag { create(:tag) }
    end
  end

  factory :hub_tag_filter, class: HubTagFilter do
    hub

    filter { filter_association(action, tag, new_tag) }
    filter_transients

    trait :owned do
      transient do
        owner create(:user)
      end
      after(:create) { |filter, evaluator| set_roles(filter, evaluator) }
    end
  end

  factory :feed_tag_filter, class: HubFeedTagFilter do
    hub_feed { association :hub_feed, hub: hub, feed: feed }

    filter { filter_association(action, tag, new_tag) }
    filter_transients

    transient do
      hub
      feed
    end
  end

  factory :item_tag_filter, class: HubFeedItemTagFilter do
    hub
    feed_item

    filter { filter_association(action, tag, new_tag) }
    filter_transients
  end
end
