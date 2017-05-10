class AddSettingTagsDelimiterToHub < ActiveRecord::Migration[5.0]
  def up
    add_column :hubs, :tags_delimiter, :string
  end

  def down
    remove_column :hubs, :tags_delimiter
  end
end
