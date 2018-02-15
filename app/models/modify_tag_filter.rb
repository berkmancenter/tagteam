# frozen_string_literal: true

# ModifyTagFilter model to distinguish modifytagfilter
class ModifyTagFilter < TagFilter
  validates :new_tag_id, presence: true
  validate :new_tag_id do
    if new_tag_id == tag_id
      errors.add(:new_tag_id, " can't be the same as the original tag")
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

  def apply(items: items_with_old_tag)
    items = filter_to_scope(items)
    # Fetch the items here because once we deactivate taggings,
    # #items_with_old_tag returns nothing.
    fetched_item_ids = items_with_old_tag(items).pluck(:id)

    deactivate_taggings!(items: items)
    FeedItem.where(id: fetched_item_ids).find_each do |item|
      new_tagging = item.taggings.build(tag: new_tag, tagger: self,
                                        context: hub.tagging_key)
      if new_tagging.valid?
        new_tagging.save!
        item.solr_index
      end
    end
    update_column(:applied, true)
  end

  def deactivates_taggings(items: items_in_scope)
    taggings = ActsAsTaggableOn::Tagging.arel_table
    selected_items_with_old_tag = items_with_old_tag(items)

    # Deactivates any taggings that have the old tag
    old_tag = taggings.grouping(
      taggings[:context].eq(hub.tagging_key).and(
        taggings[:tag_id].eq(tag.id)
      ).and(
        taggings[:taggable_type].eq('FeedItem')
      ).and(
        taggings[:taggable_id].in(items.pluck(:id))
      )
    )

    # Deactivates any taggings that result in the same tag on the same item
    # For example, if an item came in with tags 'tag1' and 'tag2', and this
    # filter changed 'tag1' to 'tag2', this deactivates 'tag2'.
    duplicate_tag = taggings.grouping(
      taggings[:context].eq(hub.tagging_key).and(
        taggings[:tag_id].eq(new_tag.id)
      ).and(
        taggings[:taggable_type].eq('FeedItem')
      ).and(
        taggings[:taggable_id].in(selected_items_with_old_tag.pluck(:id))
      )
    )

    ActsAsTaggableOn::Tagging.where(old_tag.or(duplicate_tag))
  end

  def simulate(tag_list)
    tag_list.map { |t| t == tag.name ? new_tag.name : t }.uniq
  end

  def filters_before
    previous = hub.all_tag_filters.where(
      "((type = 'ModifyTagFilter' AND new_tag_id = :tag_id) OR
        (type = 'AddTagFilter' AND tag_id = :tag_id))
       AND updated_at < :updated_at",
      tag_id: tag.id, updated_at: updated_at
    ).last
    previous ? previous.filters_before + [previous] : []
  end

  def filters_after
    subsequent = hub.all_tag_filters.where(
      "type IN ('ModifyTagFilter', 'DeleteTagFilter') AND
      tag_id = ? AND updated_at > ?", new_tag.id, updated_at
    ).first
    subsequent ? [subsequent] + subsequent.filters_after : []
  end

  def tag_changes
    { tags_modified: [tag, new_tag] }
  end
end
