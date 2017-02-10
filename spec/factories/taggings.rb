# frozen_string_literal: true
FactoryGirl.define do
  factory :tagging, class: ActsAsTaggableOn::Tagging do
    tag
    association :taggable, factory: :feed_item
    tagger { create(:add_tag_filter, tag: tag) }
    context 'tags'
  end
end
