# frozen_string_literal: true

class ChangeTagsDelimiterToArray < ActiveRecord::Migration[5.0]
  def self.up
    change_column :hubs, :tags_delimiter, :string, array: true, default: [], using: "(string_to_array(tags_delimiter, ''))"
  end

  def self.down
    change_column :hubs, :tags_delimiter, :string, array: false, default: nil, using: "(array_to_string(tags_delimiter, ''))"
  end
end
