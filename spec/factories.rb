def set_roles(object, evaluator)
  evaluator.owner.has_role!(:owner, object)
  evaluator.owner.has_role!(:creator, object)
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
      after(:create) do |hub, evaluator|
        hub.feeds << create(:feed, with_url: evaluator.with_feed_url)
      end
      transient do
        with_feed_url 0
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

    transient do
      tag 'test-tag'
    end

    trait :tagged do
      after(:create) do |item|
        item.tag_list.add(tag)
      end
    end
  end

  factory :feed do
    before(:create) { |feed| VCR.insert_cassette("feed_factory-#{URI(feed.feed_url).host}") }
    after(:create) { VCR.eject_cassette }
    transient do
      with_url 0
    end

    feed_url do |feed|
      feeds = [
       'http://reagle.org/joseph/blog/?flav=atom',
       'http://childrenshospitalblog.org/category/claire-mccarthy-md/feed/',
       'http://feeds.feedburner.com/mfeldstein/feed/',
      ]
      feeds[feed.with_url % feeds.size]
    end

    initialize_with { Feed.find_or_create_by_feed_url(feed_url) }
  end

  factory :tag, class: ActsAsTaggableOn::Tag do
    name { generate(:tag_name) }
  end

  factory :tag_filter do
    hub
    tag
    scope { hub }

    factory :add_tag_filter, class: AddTagFilter
    factory :delete_tag_filter, class: DeleteTagFilter
    factory :modify_tag_filter, class: ModifyTagFilter do
      association :new_tag, factory: :tag
    end
  end

  factory :tagging, class: ActsAsTaggableOn::Tagging do
    tag
    association :taggable, factory: :feed_item
    tagger { create(:add_tag_filter, tag: tag) }
    context 'tags'
  end
end
