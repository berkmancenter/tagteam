# frozen_string_literal: true

module FeedItems
  # Send email to users when changes are made to a feed item
  class NotificationsMailer < ApplicationMailer
    default from: Tagteam::Application.config.default_sender

    def feed_item_change_notification(hub:, modified_item:, users_to_notify:, current_user:, changes:)
      @hub = hub
      @hub_url = hub_url(@hub)
      @modified_item = modified_item
      @hub_feed = @hub.hub_feed_for_feed_item(@modified_item)
      @updated_by = current_user
      @changes = parse_changes(changes)

      subject = 'Item change in the ' + @hub.title + ' hub'

      mail(bcc: users_to_notify.collect(&:email), subject: subject)
    end

    private

    def parse_changes(changes)
      keys = %i[description title url]
      parsed_changes = []

      keys.each do |key|
        next unless changes.key?(key)

        old_value = changes[key][0]
        new_value = changes[key][1]

        parsed_changes << "#{key.to_s.capitalize} changed from '#{old_value}' to '#{new_value}'"
      end

      parsed_changes
    end
  end
end
