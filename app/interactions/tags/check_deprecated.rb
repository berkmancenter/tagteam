# frozen_string_literal: true

module Tags
  # Check if a given tag is deprecated
  class CheckDeprecated < ActiveInteraction::Base
    object :tag, class: ActsAsTaggableOn::Tag
    object :hub, class: Hub

    def execute
      is_deleted = TagFilter.where(
        tag_id: tag.id,
        type: 'DeleteTagFilter',
        hub_id: hub.id,
        scope_type: 'Hub',
        scope_id: hub.id
      ).any?

      is_replaced = TagFilter.where(
        tag_id: tag.id,
        type: 'ModifyTagFilter',
        hub_id: hub.id,
        scope_type: 'Hub',
        scope_id: hub.id
      ).any?

      is_replaced || is_deleted
    end
  end
end
