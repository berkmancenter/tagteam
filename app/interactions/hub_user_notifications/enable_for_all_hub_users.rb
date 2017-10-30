# frozen_string_literal: true

module HubUserNotifications
  # Reset notifications settings for a hub by removing any opt-out HubUserNotifications
  class EnableForAllHubUsers < ActiveInteraction::Base
    object :hub

    def execute
      HubUserNotification.where(hub: hub).destroy_all
    end
  end
end
