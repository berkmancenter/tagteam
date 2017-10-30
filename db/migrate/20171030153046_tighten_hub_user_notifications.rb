# frozen_string_literal: true

# Add uniqueness constraint and prevent null values in HubUserNotification keys
class TightenHubUserNotifications < ActiveRecord::Migration[5.0]
  def change
    add_index :hub_user_notifications, %i[hub_id user_id], unique: true
    change_column_null(:hub_user_notifications, :hub_id, false)
    change_column_null(:hub_user_notifications, :user_id, false)
  end
end
