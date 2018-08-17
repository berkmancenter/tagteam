# frozen_string_literal: true

# migration to create removed_tag_suggestions table
class CreateRemovedTagSuggestions < ActiveRecord::Migration[5.0]
  def change
    create_table :removed_tag_suggestions do |t|
      t.integer :tag_id
      t.integer :hub_id
      t.integer :user_id
    end

    add_index :removed_tag_suggestions, :hub_id
  end
end
