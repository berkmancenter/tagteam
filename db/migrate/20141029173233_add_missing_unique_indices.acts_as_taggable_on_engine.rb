# This migration comes from acts_as_taggable_on_engine (originally 2)
class AddMissingUniqueIndices < ActiveRecord::Migration
  def self.up
    remove_index :tags, :name if index_exists?(:tags, :name)
    add_index :tags, :name, unique: true

    remove_index :taggings, :tag_id
    remove_index :taggings, [:taggable_id, :taggable_type, :context]

    taggings = ActsAsTaggableOn::Tagging
      .select('min(id) as min_id, max(id) as max_id, count(*)')
      .group(:tag_id, :taggable_id, :taggable_type, :context, :tagger_id, :tagger_type)
      .having('count(*) > 1')

    taggings.each do |tagging|
      ActsAsTaggableOn::Tagging.find(tagging.min_id).delete
    end

    add_index :taggings,
              [:tag_id, :taggable_id, :taggable_type, :context, :tagger_id, :tagger_type],
              unique: true, name: 'taggings_idx'
  end

  def self.down
    remove_index :tags, :name

    remove_index :taggings, name: 'taggings_idx'
    add_index :taggings, :tag_id
    add_index :taggings, [:taggable_id, :taggable_type, :context]
  end
end
