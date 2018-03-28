# frozen_string_literal: true

# Add enable_tag_scoreboard to hubs table
class AddEnableTagScoreboardToHubs < ActiveRecord::Migration[5.0]
  def change
    add_column :hubs, :enable_tag_scoreboard, :boolean, default: false
  end
end
