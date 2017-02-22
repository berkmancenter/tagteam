class CreateHubUserNotifications < ActiveRecord::Migration[5.0]
  def up
    create_table :hub_user_notifications do |t|
      t.references(:user)
      t.references(:hub)
      t.column(:notify_about_modifications, :boolean)

      t.timestamps null: false
    end
  end

  def down
    drop_table :hub_user_notifications
  end
end
