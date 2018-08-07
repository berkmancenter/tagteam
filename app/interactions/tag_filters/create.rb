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

      # No notifications on AddTagFilter (to anyone)
      # Send notifications immediately if Delete or Modify created
      if tag_filter.scope_type == 'FeedItem'
        tag_filter.apply(items: FeedItem.where(id: scope.id))
        TaggingNotifications::ApplyTagFiltersWithNotification.perform_later(scope, tag_filter, hub, user)
      else
        TaggingNotifications::ApplyTagFiltersWithNotification.perform_later(nil, tag_filter, hub, user)
      end

      tag_filter
    end

    def find_or_create_tag_by_name(name)
      ActsAsTaggableOn::Tag.find_or_create_by_name_normalized(name)
    end
  end
end
