class AddAllowSignUpForNotificationsToHubs < ActiveRecord::Migration[5.0]
  def up
    add_column :hubs, :allow_taggers_to_sign_up_for_notifications, :boolean
  end

  def down
    remove_column :hubs, :allow_taggers_to_sign_up_for_notifications
  end
end
