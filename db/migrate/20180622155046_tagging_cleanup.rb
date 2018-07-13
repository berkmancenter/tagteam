class TaggingCleanup < ActiveRecord::Migration[5.1]
  def change
    # should be ~72:
    execute 'DELETE FROM deactivated_taggings WHERE id IN (SELECT dt.id FROM deactivated_taggings dt LEFT JOIN feed_items fi ON fi.id = dt.taggable_id WHERE fi.id IS NULL)'

    # should be ~34k:
    execute "DELETE FROM deactivated_taggings WHERE id IN (SELECT dt.id FROM tag_filters tf JOIN deactivated_taggings dt ON dt.deactivator_id = tf.id AND dt.deactivator_type = 'TagFilter' AND tf.type = 'ModifyTagFilter' AND tf.new_tag_id = dt.tag_id)"

    # Removing all crazy dups on deactivated taggings referencing the same item (probably sidekiq gone haywire?)
    # This takes ~64 mins long to run on a camp with some tuning, so commented out for now.
    # execute 'DELETE FROM deactivated_taggings d1 USING deactivated_taggings d2 WHERE d1.id < d2.id AND d1.tag_id = d2.tag_id AND d1.taggable_id = d2.taggable_id AND d1.taggable_type = d2.taggable_type AND d1.tagger_id = d2.tagger_id AND d1.tagger_type = d2.tagger_type AND d1.deactivator_id = d2.deactivator_id AND d1.deactivator_type = d2.deactivator_type AND d1.context = d2.context'
  end
end
