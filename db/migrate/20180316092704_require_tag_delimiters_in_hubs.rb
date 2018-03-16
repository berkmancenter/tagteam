# frozen_string_literal: true

# Eliminate nil values in tags_delimiter array column
class RequireTagDelimitersInHubs < ActiveRecord::Migration[5.0]
  def up
    Hub.transaction do
      Hub.where(tags_delimiter: nil).find_each do |hub|
        hub.update!(tags_delimiter: [])
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
