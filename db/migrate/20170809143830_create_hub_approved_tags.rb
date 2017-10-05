class CreateHubApprovedTags < ActiveRecord::Migration[5.0]
  def change
    create_table :hub_approved_tags do |t|
      t.references :hub, index: true
      t.string :tag, index: true
    end
  end
end
