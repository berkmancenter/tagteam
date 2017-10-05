class AddHubSettingSuggestOnlyApprovedTags < ActiveRecord::Migration[5.0]
  def up
    add_column :hubs, :suggest_only_approved_tags, :string
  end

  def down
    remove_column :hubs, :suggest_only_approved_tags
  end
end
