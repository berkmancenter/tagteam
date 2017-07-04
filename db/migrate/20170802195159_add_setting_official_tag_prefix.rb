class AddSettingOfficialTagPrefix < ActiveRecord::Migration[5.0]
  def up
    add_column :hubs, :official_tag_prefix, :string
  end

  def down
    remove_column :hubs, :official_tag_prefix
  end
end
