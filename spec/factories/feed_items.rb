# frozen_string_literal: true
FactoryGirl.define do
  factory :feed_item do
    title 'Test Title'
    sequence(:url) { |n| "http://example.com/?tag=#{n}" }

    transient do
      tag { generate(:tag_name) }
      tag_context 'tags'
    end

    trait :tagged do
      before(:create) do |item|
        # The callbacks need to be run in the correct order
        item.skip_global_tag_copy = true
      end
      after(:create) do |item, evaluator|
        item.set_tag_list_on(evaluator.tag_context, evaluator.tag)
        item.save!
        item.copy_global_tags_to_hubs
      end
    end

    factory :feed_item_from_feed do
      transient do
        feed { create(:feed) }
      end

      after(:create) do |item, evaluator|
        item.feeds << evaluator.feed
        item.save!
      end
    end
  end
end
