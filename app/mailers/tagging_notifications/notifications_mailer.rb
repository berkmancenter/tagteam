# frozen_string_literal: true

module TaggingNotifications
  # Send email to user with tagging changes made to their item
  class NotificationsMailer < ActionMailer::Base
    default from: Tagteam::Application.config.default_sender

    def tagging_change_notification(hub, modified_item, item_users, current_user, changes)
      @hub = hub
      @hub_url = hub_url(@hub)
      @modified_item = modified_item
      @hub_feed = @hub.hub_feed_for_feed_item(@modified_item)
      @updated_by = current_user
      @changes = parse_changes(changes)

      subject = 'Tagging update in the ' + @hub.title + ' hub'
      mail(bcc: item_users.collect(&:email), subject: subject)
    end

    private

    def parse_changes(changes)
      change_type, tags = changes.first

      case change_type.to_sym
      when :tags_added
        "Tags added: #{tags.join(', ')}"
      when :tags_modified
        "Tags modified: #{tags.first} was changed to #{tags.last}"
      when :tags_deleted
        "Tags deleted: #{tags.join(', ')}"
      end
    end
  end
end
