# frozen_string_literal: true

module TaggingNotifications
  # Send email to user with tagging changes made to their item
  class NotificationsMailer < ActionMailer::Base
    default from: Tagteam::Application.config.default_sender,
      return_path: Tagteam::Application.config.return_path

    def tagging_change_notification(hub, modified_items, user_to_notify, updated_by_user, changes)
      @hub = hub
      @modified_items = modified_items
      @updated_by_display = updated_by_user == user_to_notify ? 'Tag filters have' : "#{updated_by_user.username} has"
      @changes = parse_changes(changes)

      subject = 'Tagging update in the ' + @hub.title + ' hub'
      mail(to: user_to_notify.email, subject: subject)
    end

    private

    def parse_changes(changes)
      all_changes = []
      changes.each do |change|
      case change[:type].to_sym
        when :tags_modified
          all_changes << "Tags modified: #{change[:values].first.join(', ')} changed to: #{change[:values].last.join(', ')}"
        when :tags_deleted
          all_changes << "Tags deleted: #{change[:values].first}"
        when :tags_added
          all_changes << "Tags added: #{change[:values].first}"
        when :tags_supplemented
          all_changes << "Tag #{change[:values].first} has been supplemented with tag #{change[:values].last}"
        when :tags_supplemented_deletion
          all_changes << "Tag #{change[:values].first} is no longer being supplemented with tag #{change[:values].last}"
        end
      end
      all_changes.join(', ')
    end
  end
end
