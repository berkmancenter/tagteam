# frozen_string_literal: true

# A TagFilter type used to supplement existing tags with a second tag.
# Similar to a ModifyTagFilter but the original tag is preserved instead of replaced.
class SupplementTagFilter < TagFilter
  validates :new_tag_id, presence: true

  validate :new_tag_id do
    errors.add(:new_tag_id, " can't be the same as the original tag") if new_tag_id == tag_id
  end

  def items_with_old_tag(items = items_in_scope)
    items.tagged_with(tag.name, on: hub.tagging_key)
  end

  def apply(items: items_with_old_tag)
    items = filter_to_scope(items)

    items.find_each do |item|
      new_tagging = item.taggings.build(tag: new_tag, tagger: self, context: hub.tagging_key)

      if new_tagging.valid?
        new_tagging.save!
        item.solr_index
      end
    end

    update(applied: true)
  end
end
