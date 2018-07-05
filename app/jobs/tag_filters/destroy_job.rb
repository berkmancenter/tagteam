# frozen_string_literal: true

module TagFilters
  # Revert (rollback) and destroy a TagFilter
  class DestroyJob < ApplicationJob
    queue_as :default

    def perform(tag_filter, current_user)
      hub = tag_filter.hub

      TaggingNotifications::SendNotificationJob.perform_later(
        hub,
        tag_filter.filtered_feed_items,
        [tag_filter],
        current_user,
        determine_changes(tag_filter)
      )

      tag_filter.rollback
      tag_filter.destroy
    end

    private

    def determine_changes(tag_filter)
      case tag_filter.class.to_s
      when 'AddTagFilter'
        { tags_deleted: [tag_filter.tag_name] }
      when 'DeleteTagFilter'
        { tags_added: [tag_filter.tag_name] }
      when 'ModifyTagFilter'
        { tags_modified: [[tag_filter.new_tag_name, tag_filter.tag_name]] }
      when 'SupplementTagFilter'
        { tags_supplemented_deletion: [[tag_filter.tag_name, tag_filter.new_tag_name]] }
      else
        raise 'Unknown tag filter type'
      end
    end
  end
end
