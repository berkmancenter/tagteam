class AddTagFilter < TagFilter
  def apply
    items_in_scope.each do |item|
      item.taggings.create(tag: tag, tagger: self, context: hub.tagging_key)
    end
    deactivate_taggings!
  end

  def rollback
    # This needs to happen first so we can figure out which taggings to leave
    # deactivated.
    reactivate_taggings!
    taggings.destroy_all
  end

  def deactivates_taggings
    ActsAsTaggableOn::Tagging.where(
      context: hub.tagging_key, tag_id: tag.id, active: true
    ).order('created_at DESC').limit(1)
  end

  def reactivates_taggings
    # This filter's taggings still exist, so we have to make sure not to pick
    # them
    reactivatable = ActsAsTaggableOn::Tagging.where(
      context: hub.tagging_key, tag_id: tag.id, active: false
    ).where('tagger_id != ? AND tagger_type != ?', id, self.class.name).
      order('created_at DESC').limit(1)

    # We don't want to reactivate any taggings that shouldn't be reactived.
    # For example, a filter might have been added later than this one.
    if taggings.where(active: false).count > 0
      # This could probably be done with some crazy join
      deactivated_tag_ids = taggings.where(active: false).pluck(:tag_id)
      reactivatable = reactivatable.where('tag_id NOT IN ?', deactivated_tag_ids)
    end

    return reactivatable
  end
end
