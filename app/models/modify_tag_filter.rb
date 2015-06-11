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

  def items_with_old_tag(items = items_in_scope)
    items.tagged_with(tag.name, on: hub.tagging_key)
  end

  def items_with_new_tag(items = items_in_scope)
    items.tagged_with(new_tag.name, on: hub.tagging_key, owned_by: self)
  end

  def apply(items: items_in_scope)
    fetched_items = items.all
    deactivate_taggings!(items: items)
    fetched_items.each do |item|
      new_tagging = item.taggings.build(tag: new_tag, tagger: self,
                                        context: hub.tagging_key)
      new_tagging.save! if new_tagging.valid?
    end
    self.update_attribute(:applied, true)
  end

  def deactivates_taggings(items: items_in_scope)
    taggings = ActsAsTaggableOn::Tagging.arel_table
    selected_items_with_old_tag = items_with_old_tag(items)

    # Deactivates any taggings that have the old tag
    old_tag = taggings.grouping(
      taggings[:context].eq(hub.tagging_key).and(
      taggings[:tag_id].eq(tag.id)).and(
      taggings[:taggable_type].eq('FeedItem')).and(
      taggings[:taggable_id].in(items.pluck(:id))))

    # Deactivates any taggings that result in the same tag on the same item
    # For example, if an item came in with tags 'tag1' and 'tag2', and this
    # filter changed 'tag1' to 'tag2', this deactivates 'tag2'.
    duplicate_tag = taggings.grouping(
      taggings[:context].eq(hub.tagging_key).and(
      taggings[:tag_id].eq(new_tag.id)).and(
      taggings[:taggable_type].eq('FeedItem')).and(
      taggings[:taggable_id].in(selected_items_with_old_tag.pluck(:id))))

    ActsAsTaggableOn::Tagging.where(old_tag.or(duplicate_tag))
  end

  def reactivates_taggings
    d_taggings = DeactivatedTagging.arel_table

    # Reactivates any taggings that resulted in the same tag on the same item.
    # For example, if an item came in with tags 'tag1' and 'tag2', and this
    # filter changed 'tag1' to 'tag2', this section reactivates 'tag2' while
    # the next section reactivates 'tag1'.
    duplicate_tag = d_taggings.grouping(
      d_taggings[:context].eq(hub.tagging_key).and(
      d_taggings[:tag_id].eq(new_tag.id)).and(
      d_taggings[:taggable_type].eq('FeedItem')).and(
      d_taggings[:taggable_id].in(items_with_new_tag.pluck(:id))))

    # Reactivates any taggings that had the old tag
    old_tag = d_taggings.grouping(
      d_taggings[:context].eq(hub.tagging_key).and(
      d_taggings[:tag_id].eq(tag.id)).and(
      d_taggings[:taggable_type].eq('FeedItem')).and(
      d_taggings[:taggable_id].in(items_with_new_tag.pluck(:id))))

    DeactivatedTagging.where(old_tag.or(duplicate_tag))
  end
end
