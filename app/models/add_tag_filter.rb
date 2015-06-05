class AddTagFilter < TagFilter
  def deactivates_taggings
    # Deactivates any taggings that are the same except in owner
    ActsAsTaggableOn::Tagging.
      where(context: hub.tagging_key, tag_id: tag.id, taggable_type: FeedItem).
      where('taggable_id IN ?', items_in_scope.pluck(:id))
  end

  def reactivates_taggings
    # If this filter has any deactivated taggings, we shouldn't reactivate
    # anything behind them in line.
    DeactivatedTagging.
      where(context: hub.tagging_key, tag_id: tag.id, taggable_type: FeedItem).
      where('taggable_id IN ?', items_in_scope.pluck(:id)).
      where('taggable_id NOT IN ?', deactivated_taggings.pluck(:taggable_id))
  end
end
