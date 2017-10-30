# frozen_string_literal: true

module Hubs
  # Update tagging-related Hub attributes
  class UpdateTaggingSettings < ActiveInteraction::Base
    object :hub
    string :tags_delimiter
    string :official_tag_prefix
    string :suggest_only_approved_tags, default: nil
    string :hub_approved_tags

    def execute
      hub.assign_attributes(
        tags_delimiter: tags_delimiter,
        official_tag_prefix: official_tag_prefix,
        suggest_only_approved_tags: suggest_only_approved_tags,
        hub_approved_tags: split_hub_approved_tags(hub_approved_tags)
      )

      errors.merge!(hub.errors) unless hub.save

      hub
    end

    private

    def split_hub_approved_tags(tags)
      tags
        .split("\r\n")
        .uniq
        .map { |approved_tag| HubApprovedTag.new(tag: approved_tag, hub_id: @hub.id) }
    end
  end
end
