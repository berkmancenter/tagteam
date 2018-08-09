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

  # Options are either item_ids passed in, or nothing passed in
  def apply(item_ids = [])
    items = item_ids.any? ? FeedItem.where(id: item_ids).tagged_with(tag.name, on: hub.tagging_key) :
      scope.taggable_items.tagged_with(tag.name, on: hub.tagging_key)

    # This deactivates old and duplicate tags, which forces the cache to clear
    deactivate_taggings!(items.map(&:id))

    # Mass insert
    values = items.map { |item| "(#{new_tag.id},#{item.id},'FeedItem',#{self.id},'TagFilter','#{hub.tagging_key}')" }.join(',')
    ActiveRecord::Base.connection.execute("INSERT INTO taggings (tag_id, taggable_id, taggable_type, tagger_id, tagger_type, context) VALUES #{values}")
    items.each { |item| item.solr_index }

    update_column(:applied, true)
  end

  def deactivates_taggings(item_ids)
    taggings = ActsAsTaggableOn::Tagging.arel_table

    # Deactivates any taggings that have the old tag
    old_tag = taggings.grouping(
      taggings[:context].eq(hub.tagging_key).and(
        taggings[:tag_id].eq(tag.id)
      ).and(
        taggings[:taggable_type].eq('FeedItem')
      ).and(
        taggings[:taggable_id].in(item_ids)
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
        taggings[:taggable_id].in(item_ids)
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
