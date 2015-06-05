class ModifyTagFilter < TagFilter
  validates_presence_of :new_tag_id
  validate :new_tag_id do
    if self.new_tag_id == self.tag_id
      self.errors.add(:new_tag_id, " can't be the same as the original tag")
    end
  end

  attr_accessible :new_tag_id

  api_accessible :default do |t|
    t.add :new_tag
  end

  def description
    'Change'
  end

  def items_with_old_tag
    items_in_scope.tagged_with(tag.name, on: hub.tagging_key)
  end

  def items_with_new_tag
    items_in_scope.tagged_with(new_tag.name, on: hub.tagging_key, owned_by: self)
  end

  def apply(items: affects_items)
    deactivate_taggings!(items: items)
    items.each do |item|
      item.taggings.create(tag: new_tag, tagger: self, context: hub.tagging_key)
    end
  end

  def deactivates_taggings(items: items_with_old_tag)
    taggings = ActsAsTaggableOn::Tagging.arel_table

    # Deactivates any taggings that have the old tag
    old_tag = taggings.
      where(context: hub.tagging_key, tag_id: tag.id, taggable_type: FeedItem).
      where('taggable_id IN ?', items.pluck(:id))

    # Deactivates any taggings that result in the same tag on the same item
    duplicate_tag = taggings.
      where(context: hub.tagging_key, tag_id: new_tag.id,
            taggable_type: FeedItem).
      where('taggable_id IN ?', items.pluck(:id))

    ActsAsTaggableOn::Tagging.where(old_tag.or(duplicate_tag))
  end

  def reactivates_taggings
    deactivated_taggings = DeactivatedTagging.arel_table

    # Reactivates any taggings that resulted in the same tag on the same item.
    # For example, if an item came in with tags 'tag1' and 'tag2', and this
    # filter changed 'tag1' to 'tag2', this section reactivates 'tag2' while
    # the next section reactivates 'tag1'.
    duplicate_tag = deactivated_taggings.
      where(context: hub.tagging_key, tag_id: new_tag.id,
            taggable_type: FeedItem).
      where('taggable_id IN ?', items_with_new_tag.pluck(:id))

    # Reactivates any taggings that had the old tag
    old_tag = deactivated_taggings.
      where(context: hub.tagging_key, tag_id: tag.id, taggable_type: FeedItem).
      where('taggable_id IN ?', items_with_new_tag.pluck(:id))

    deactivated_taggings.where(old_tag.or(duplicate_tag))
  end
end
