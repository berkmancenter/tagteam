# frozen_string_literal: true

module Hubs
  # Update tagging-related Hub attributes
  class UpdateTaggingSettings < ActiveInteraction::Base
    object :hub
    string :tags_delimiter
    string :official_tag_prefix
    string :suggest_only_approved_tags, default: nil
    string :hub_approved_tags
    boolean :bookmarklet_empty_description_reminder, default: false
    boolean :enable_tag_scoreboard, default: false

    def execute
      assign_attributes

      errors.merge!(hub.errors) unless hub.save

      hub
    end

    private

    def assign_attributes
      hub.tags_delimiter << tags_delimiter
      hub.official_tag_prefix = official_tag_prefix
      hub.suggest_only_approved_tags = suggest_only_approved_tags
      hub.hub_approved_tags = split_hub_approved_tags(hub_approved_tags)
      hub.bookmarklet_empty_description_reminder = bookmarklet_empty_description_reminder
      hub.enable_tag_scoreboard = enable_tag_scoreboard
    end

    def split_hub_approved_tags(tags)
      tags
        .split("\r\n")
        .uniq
        .map { |approved_tag| HubApprovedTag.new(tag: approved_tag, hub_id: @hub.id) }
    end
  end
end
