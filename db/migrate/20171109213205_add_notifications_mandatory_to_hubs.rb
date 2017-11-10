class AddNotificationsMandatoryToHubs < ActiveRecord::Migration[5.0]
  def change
    add_column :hubs, :notifications_mandatory, :boolean, null: false, default: false
  end
end
