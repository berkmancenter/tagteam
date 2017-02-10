# frozen_string_literal: true
FactoryGirl.define do
  factory :tag, class: ActsAsTaggableOn::Tag do
    name { generate(:tag_name) }
  end
end
