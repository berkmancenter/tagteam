# frozen_string_literal: true
FactoryGirl.define do
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
end
