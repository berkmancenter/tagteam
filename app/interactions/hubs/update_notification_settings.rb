# frozen_string_literal: true

module Hubs
  # Update notification-related Hub attributes
  class UpdateNotificationSettings < ActiveInteraction::Base
    object :hub
    boolean :notify_taggers

    def execute
      hub.notify_taggers = notify_taggers

      if hub.save
        compose(HubUserNotifications::EnableForAllHubUsers, hub: hub) if notify_taggers?
      else
        errors.merge!(hub.errors)
      end

      hub
    end
  end
end
