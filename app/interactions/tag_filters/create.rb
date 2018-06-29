# frozen_string_literal: true
module TagFilters
  # Create a TagFilter
  class Create < ActiveInteraction::Base
    string :filter_type
    object :hub
    object :hub_feed, default: nil
    string :modify_tag_name, default: nil
    string :new_tag_name
    object :scope, class: TagScopable
    integer :tag_id, default: nil
    object :user

    validates :filter_type, inclusion: { in: %w[AddTagFilter DeleteTagFilter ModifyTagFilter SupplementTagFilter] }

    # TODO: Refactor this too-large method that was formerly the TagFiltersController#create action
    def execute
      filter_type_class = filter_type.constantize

      tag = ActsAsTaggableOn::Tag.find(tag_id) if tag_id.present?

      @new_tag_name = @new_tag_name.chomp('.') if @new_tag_name.end_with?('.')
      @new_tag_name = @new_tag_name[1..-1] if @new_tag_name.start_with?('.')

      hub.tags_delimiter.each do |delimiter|
        @new_tag_name.slice!(delimiter)
      end

      @new_tag_name.delete(hub.tags_delimiter.join) if @new_tag_name.present?

      if [ModifyTagFilter, SupplementTagFilter].include?(filter_type_class)
        tag ||= find_or_create_tag_by_name(modify_tag_name)
        new_tag = find_or_create_tag_by_name(new_tag_name)
      else
        tag ||= find_or_create_tag_by_name(new_tag_name)
      end

      tag_filter = filter_type_class.new
      tag_filter.hub = hub
      tag_filter.scope = scope
      tag_filter.tag = tag
      tag_filter.new_tag = new_tag if new_tag.present?

      return tag_filter unless tag_filter.save

      user.has_role!(:owner, tag_filter)
      user.has_role!(:creator, tag_filter)

      if hub.notify_taggers?
        changes =
          case filter_type
          when 'AddTagFilter'
            { tags_added: [tag.name] }
          when 'DeleteTagFilter'
            { tags_deleted: [tag.name] }
          when 'ModifyTagFilter'
            { tags_modified: [tag.name, new_tag.name] }
          when 'SupplementTagFilter'
            { tags_supplemented: [tag.name, new_tag.name] }
          end

        # Note, this isn't doing anything for the tag_filter as scope
        TaggingNotifications::SendNotificationJob.perform_later(
          tag_filter,
          hub,
          user,
          changes
        )
      end

      tag_filter.apply_async
      if tag_filter.type == 'AddTagFilter' && tag_filter.scope_type == 'FeedItem'
        hub.all_tag_filters.each do |old_filter|
          next if old_filter.scope_type == 'FeedItem'
          old_filter.apply_async(true)
        end
      end

      tag_filter
    end

    def find_or_create_tag_by_name(name)
      ActsAsTaggableOn::Tag.find_or_create_by_name_normalized(name)
    end
  end
end
