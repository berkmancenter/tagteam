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

  def affects_items
    items_in_scope.tagged_with(tag.name, on: hub.tagging_key)
  end

  def apply
    deactivate_taggings!
    affects_items.each do |item|
      item.taggings.create(tag: new_tag, tagger: self, context: hub.tagging_key)
    end
  end

  def deactivates_taggings
    taggings = ActsAsTaggableOn::Tagging.arel_table

    # Deactivates any taggings that have the old tag
    old_tag = taggings.
      where(context: hub.tagging_key, tag_id: tag.id, taggable_type: FeedItem).
      where('taggable_id IN ?', affects_items.pluck(:id))

    # Deactivates any taggings that result in the same tag on the same item
    duplicate_tag = taggings.
      where(context: hub.tagging_key, tag_id: new_tag.id,
            taggable_type: FeedItem).
      where('taggable_id IN ?', affects_items.pluck(:id))

    ActsAsTaggableOn::Tagging.where(old_tag.or(duplicate_tag))
  end

  def reactivates_taggings
  end
end
