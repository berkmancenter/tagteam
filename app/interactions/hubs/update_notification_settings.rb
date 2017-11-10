# frozen_string_literal: true

module Hubs
  # Update notification-related Hub attributes
  class UpdateNotificationSettings < ActiveInteraction::Base
    object :hub
    boolean :notify_taggers, default: false
    boolean :notifications_mandatory, default: false

    def execute
      hub.notify_taggers = notify_taggers
      hub.notifications_mandatory = notifications_mandatory

      if hub.save
        compose(HubUserNotifications::EnableForAllHubUsers, hub: hub) if notifications_mandatory?
      else
        errors.merge!(hub.errors)
      end

      hub
    end
  end
end
