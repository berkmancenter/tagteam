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
        [determine_changes(tag_filter)]
      )

      tag_filter.rollback
      tag_filter.destroy
    end

    private

    def determine_changes(tag_filter)
      case tag_filter.class.to_s
      when 'AddTagFilter'
        { type: 'tags_deleted', values: [tag_filter.tag_name] }
      when 'DeleteTagFilter'
        { type: 'tags_added', values: [tag_filter.tag_name] }
      when 'ModifyTagFilter'
        { type: 'tags_modified', values: [[tag_filter.new_tag_name], [tag_filter.tag_name]] }
      when 'SupplementTagFilter'
        { type: 'tags_supplemented_deletion', values: [[tag_filter.tag_name, tag_filter.new_tag_name]] }
      else
        raise 'Unknown tag filter type'
      end
    end
  end
end
