# frozen_string_literal: true

# It relates user and tag, which are not allow to display in the suggestion list of tags.
class RemovedTagSuggestion < ApplicationRecord
  belongs_to :tag, class_name: 'ActsAsTaggableOn::Tag'
  belongs_to :user
  belongs_to :hub
end
