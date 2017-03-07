class AddApprovedToUser < ActiveRecord::Migration[5.0]
  def up
    add_column :users, :approved, :boolean, default: false, null: false
    add_index :users, :approved

    User.update_all(approved: true)
  end

  def down
    remove_index :users, :approved
    remove_column :users, :approved
  end
end
