class AddUnsubscribeToFeeds < ActiveRecord::Migration[5.0]
  def change
    add_column :feeds, :unsubscribe, :boolean, default: false
  end
end
