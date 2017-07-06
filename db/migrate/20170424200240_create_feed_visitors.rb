class CreateFeedVisitors < ActiveRecord::Migration[5.0]
  def up
    create_table :feed_visitors do |t|
      t.string :route
      t.string :ip, limit: 15
      t.string :user_agent

      t.timestamps
    end
  end

  def down
    drop_table :feed_visitors
  end
end
