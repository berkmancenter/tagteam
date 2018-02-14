# frozen_string_literal: true

class ChangeTagsDelimiterToArray < ActiveRecord::Migration[5.0]
  def self.up
    Hub.find_each do |hub|
      hub.update(tags_delimiter: hub.tags_delimiter.split('')) if hub.tags_delimiter.present?
    end
  end

  def self.down
    Hub.find_each do |hub|
      hub.update(tags_delimiter: hub.tags_delimiter.join) if hub.tags_delimiter.present?
    end
  end
end
