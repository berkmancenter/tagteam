# frozen_string_literal: true

module Tags
  # Check if a given tag is deprecated
  class CheckApproved < ActiveInteraction::Base
    object :tag, class: ActsAsTaggableOn::Tag
    object :hub, class: Hub

    def execute
      tag.name.in?(hub.settings[:hub_approved_tags].map(&:tag))
    end
  end
end
