class CreateFeedSubscribers < ActiveRecord::Migration[5.0]
  def up
    create_table :feed_subscribers do |t|
      t.string :route
      t.string :ip, limit: 15
      t.string :user_agent

      t.timestamps
    end

    add_index :feed_subscribers,
              [:route, :ip, :user_agent],
              unique: true,
              name: 'feed_subscribers_uniq_comb'
  end

  def down
    drop_table :feed_subscribers
  end
end
