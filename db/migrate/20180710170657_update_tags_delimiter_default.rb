class UpdateTagsDelimiterDefault < ActiveRecord::Migration[5.0]
  def up
    execute 'ALTER TABLE hubs ALTER COLUMN tags_delimiter SET DEFAULT \'{",",⎵}\'::character varying[]'
    Hub.all.find_each do |hub|
      hub.update_attribute(:tags_delimiter, [',', '⎵'])
    end
  end

  def down
    execute 'ALTER TABLE hubs ALTER COLUMN tags_delimiter SET DEFAULT \'{}\'::character varying[]'
  end
end
