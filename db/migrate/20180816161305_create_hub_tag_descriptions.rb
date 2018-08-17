class CreateHubTagDescriptions < ActiveRecord::Migration[5.1]
  def change
    create_table :hub_tag_descriptions do |t|
      t.references :hub, nil: false
      t.references :tag, nil: false
      t.string :description, limit: 400 
      t.timestamps
    end

    add_index :hub_tag_descriptions, [:hub_id, :tag_id], unique: true
  end
end
