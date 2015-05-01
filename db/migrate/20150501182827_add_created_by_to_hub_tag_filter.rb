class AddCreatedByToHubTagFilter < ActiveRecord::Migration
  def change
    add_column :hub_tag_filters, :created_by_type, :string
    add_column :hub_tag_filters, :created_by_id, :integer
  end
end
