# frozen_string_literal: true

module TaggingNotifications
  # Send email to user with tagging changes made to their item
  class NotificationsMailer < ActionMailer::Base
    default from: Tagteam::Application.config.default_sender

    def feed_wide_tagging_change(changes:, current_user:, feed_item_count:, hub_feed:, users_to_notify:)
      @changed_by = current_user
      @changes = parse_changes(changes)
      @feed_item_count = feed_item_count
      @hub_feed = hub_feed
      @hub = @hub_feed.hub

      subject = 'Tagging update in the ' + @hub.title + ' hub'

      mail(bcc: users_to_notify.collect(&:email), subject: subject)
    end

    def hub_wide_tagging_change(changes:, current_user:, feed_item_count:, hub:, users_to_notify:)
      @changed_by = current_user
      @changes = parse_changes(changes)
      @feed_item_count = feed_item_count
      @hub = hub

      subject = 'Tagging update in the ' + @hub.title + ' hub'

      mail(bcc: users_to_notify.collect(&:email), subject: subject)
    end

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
      when :tags_supplemented
        "Tag #{tags.first} has been supplemented with tag #{tags.last}"
      when :tags_supplemented_deletion
        "Tag #{tags.first} is no longer being supplemented with tag #{tags.last}"
      end
    end
  end
end
