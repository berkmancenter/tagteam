# frozen_string_literal: true

module Statistics
  class HubPrefixedTags < ActiveInteraction::Base
    array :tag_counts do
      object class: ActsAsTaggableOn::Tag
    end

    def execute
      tags_prefixed = {}

      tag_counts.each do |tag|
        split_tag = tag.name.split('.')

        next if split_tag.length < 2

        tags_prefixed[split_tag.first] = (tags_prefixed[split_tag.first] || 0) + 1
      end

      tags_prefixed.sort_by { |_key, value| value }.reverse.to_h
    end
  end
end
