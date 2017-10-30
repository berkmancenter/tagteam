class UpdateHubUserNotificationDefaults < ActiveRecord::Migration[5.0]
  def change
    change_column_default :hub_user_notifications, :notify_about_modifications, true
  end
end
