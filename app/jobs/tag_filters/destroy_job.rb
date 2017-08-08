# frozen_string_literal: true

module TagFilters
  # Revert (rollback) and destroy a TagFilter
  class DestroyJob < ApplicationJob
    queue_as :default

    def perform(tag_filter, current_user)
      hub = tag_filter.hub

      tag_filter.rollback

      send_tagging_change_notification(tag_filter, hub, current_user) if hub.notify_taggers?

      tag_filter.destroy
    end

    private

    def send_tagging_change_notification(tag_filter, hub, current_user)
      changes = determine_changes(tag_filter)

      TaggingNotifications::SendNotificationJob.perform_later(
        tag_filter,
        hub,
        current_user,
        changes
      )
    end

    # When rolling back a tag filter the tagging changes are the opposite of when the tag filter was added
    def determine_changes(tag_filter)
      case tag_filter.class.to_s
      when 'AddTagFilter'
        { tags_deleted: [tag_filter.tag_name] }
      when 'DeleteTagFilter'
        { tags_added: [tag_filter.tag_name] }
      when 'ModifyTagFilter'
        { tags_modified: [tag_filter.new_tag_name, tag_filter.tag_name] }
      else
        raise 'Unknown tag filter type'
      end
    end
  end
end
