# frozen_string_literal: true

# Remove obsolete setting from hubs
class RemoveAllowTaggersToSignUpForNotificationsFromHubs < ActiveRecord::Migration[5.0]
  def up
    remove_column :hubs, :allow_taggers_to_sign_up_for_notifications
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
