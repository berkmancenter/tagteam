# frozen_string_literal: true
module TaggingNotifications
  class ApplyTagFiltersWithNotification < ApplicationJob
    queue_as :default

    # This is a combined method because you can't async them, IE, you need to have apply tag filters
    # finish before send notification job starts to identify tag filter data
    def perform(tag_filter, hub, updated_by_user)
      ::ApplyTagFilters.new.perform([tag_filter.id], [], false)
      changes =
        case tag_filter.class.to_s
        when 'DeleteTagFilter'
          { type: :tags_deleted, values: [tag_filter.tag.name] }
        when 'ModifyTagFilter'
          { type: :tags_modified, values: [[tag_filter.tag.name], [tag_filter.new_tag.name]] }
        when 'SupplementTagFilter'
          { type: :tags_supplemented, values: [[tag_filter.tag.name, tag_filter.new_tag.name]] }
        end
      SendNotificationJob.new.perform(hub, tag_filter.filtered_feed_items, [tag_filter], updated_by_user, [changes], :owners)
    end
  end
end
