class AddCreatedByToHubFeedItemTagFilter < ActiveRecord::Migration[4.2]
  def change
    add_column :hub_feed_item_tag_filters, :created_by_type, :string
    add_column :hub_feed_item_tag_filters, :created_by_id, :integer
  end
end
