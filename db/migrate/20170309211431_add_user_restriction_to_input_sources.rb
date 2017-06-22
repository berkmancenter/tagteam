class AddUserRestrictionToInputSources < ActiveRecord::Migration[5.0]
  def up
    add_column :input_sources, :created_by_only_id, :integer
  end
  
  def down
    remove_column :input_sources, :created_by_only_id, :integer
  end
end
