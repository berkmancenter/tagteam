class AddTaggersNotificationToHubs < ActiveRecord::Migration[5.0]
  def up
    add_column :hubs, :notify_taggers, :boolean
  end

  def down
    remove_column :hubs, :notify_taggers
  end
end
