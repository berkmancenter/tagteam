# frozen_string_literal: true

module TaggingNotifications
  # Send email to user with tagging changes made to their item
  class NotificationsMailer < ActionMailer::Base
    default from: Tagteam::Application.config.default_sender

    def tagging_change_notification(hub, modified_items, user_to_notify, updated_by_user, changes)
      @hub = hub
      @modified_items = modified_items
      @updated_by_display = updated_by_user == user_to_notify ? 'Previous tag filters have' : "#{updated_by_user.username} has"
      @changes = parse_changes(changes)

      subject = 'Tagging update in the ' + @hub.title + ' hub'
      mail(to: user_to_notify.email, subject: subject)
    end

    private

    def parse_changes(changes)
      all_changes = []
      changes.each do |change|
        change_type, tags = change
        tags.each do |tag_set|
          case change_type.to_sym
          when :tags_modified
            all_changes << "Tags modified: #{tag_set.first} was changed to #{tag_set.last}"
          when :tags_deleted
            all_changes << "Tags deleted: #{tags.first}"
          when :tags_added
            all_changes << "Tags added: #{tags.first}"
          when :tags_supplemented
            all_changes << "Tag #{tag_set.first} has been supplemented with tag #{tag_set.last}"
          when :tags_supplemented_deletion
            all_changes << "Tag #{tag_set.first} is no longer being supplemented with tag #{tag_set.last}"
          end
        end
      end
      all_changes.join(', ')
    end
  end
end
