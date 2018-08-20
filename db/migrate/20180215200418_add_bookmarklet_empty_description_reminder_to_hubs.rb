# frozen_string_literal: true

class AddBookmarkletEmptyDescriptionReminderToHubs < ActiveRecord::Migration[5.0]
  def up
    add_column :hubs, :bookmarklet_empty_description_reminder, :boolean
  end

  def down
    remove_column :hubs, :bookmarklet_empty_description_reminder
  end
end
