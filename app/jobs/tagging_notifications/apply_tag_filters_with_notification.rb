# frozen_string_literal: true
module TaggingNotifications
  class ApplyTagFiltersWithNotification < ApplicationJob
    queue_as :default

    # This is a combined method because you can't async them, IE, you need to have apply tag filters
    # finish before send notification job starts to identify tag filter data
    def perform(feed_item, tag_filter, hub, updated_by_user)
      changes = []

      if feed_item.present?
        tags_before = feed_item.applied_tags(hub).map(&:name)
        ::ApplyTagFilters.new.perform(hub.all_tag_filters.select { |tf| tf.scope_type != 'FeedItem' }.map(&:id), [feed_item.id], true)
        tags_after = feed_item.applied_tags(hub).map(&:name)

        if tag_filter.present?
          # In the case of a tag filter being applied and terminating in another filter,
          # the updater is sent a notification
          if ['AddTagFilter', 'ModifyTagFilter'].include?(tag_filter.type)
            tag_name = tag_filter.type == 'AddTagFilter' ? tag_filter.tag.name : tag_filter.new_tag.name
            resulting_tag_filter = TagFilter.find_recursive(hub.id, tag_name)
            if resulting_tag_filter.present?
              mod_changes = []
              if resulting_tag_filter.type == 'DeleteTagFilter'
                mod_changes << { type: :tags_deleted, values: [tag_name] }
              elsif resulting_tag_filter.type == 'ModifyTagFilter'
                mod_changes << { type: :tags_modified, values: [[tag_name], [resulting_tag_filter.new_tag.name]] }
              end
              SendNotificationJob.new.perform(hub, [feed_item], [], updated_by_user, mod_changes, :updater)
            end
          end

          if tags_before != tags_after
            if tags_after.size > tags_before.size #Added
              changes << { type: :tags_added, values: (tags_after - tags_before).join(', ') }
            elsif tags_after.size < tags_before.size #Removed
              changes << { type: :tags_deleted, values: (tags_before - tags_after).join(', ') }
            else #Modified
              intersection = tags_after & tags_before
              before_tag = tags_before - intersection
              after_tag = tags_after - intersection
              changes << { type: :tags_modified, values: [before_tag, after_tag] }
            end
          end
          # If changes can't be calculated b/c it's a delete tag
          if changes.empty? && tag_filter.class.to_s == 'DeleteTagFilter'
            changes = { type: :tags_deleted, values: [tag_filter.tag.name] }
          end
          SendNotificationJob.new.perform(hub, [feed_item], [], updated_by_user, changes.uniq, :owners)
        else
          # If this is a new feed item, send to owner/updater
          DeactivatedTagging.where(taggable_id: feed_item.id, deactivator_type: 'TagFilter', context: "hub_#{hub.id}").map(&:deactivator).uniq.each do |deactivator|
            if deactivator.is_a?(DeleteTagFilter)
              changes << { type: :tags_deleted, values: [deactivator.tag.name] }
            elsif deactivator.is_a?(ModifyTagFilter)
              changes << { type: :tags_modified, values: [[deactivator.tag.name], [deactivator.new_tag.name]] }
            end
          end
          SendNotificationJob.new.perform(hub, [feed_item], [], updated_by_user, changes.uniq, :updater)
        end
      elsif tag_filter.present?
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
end
