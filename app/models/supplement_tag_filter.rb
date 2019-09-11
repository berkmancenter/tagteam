# frozen_string_literal: true

# A TagFilter type used to supplement existing tags with a second tag.
# Similar to a ModifyTagFilter but the original tag is preserved instead of replaced.
class SupplementTagFilter < TagFilter
  validates :new_tag_id, presence: true

  validate :new_tag_id do
    errors.add(:new_tag_id, " can't be the same as the original tag") if new_tag_id == tag_id
  end

  def apply(item_ids = [])
    if item_ids.any?
      item_ids &= scope.taggable_items.pluck(:id)
      items = FeedItem.where(id: item_ids)
    else
      items = scope.taggable_items
    end

    items = items.tagged_with(tag.name, on: hub.tagging_key)

    # TODO: This can be done, but caching would need to be dealt with
    #values = items.map { |item| "(#{new_tag.id},#{item.id},'FeedItem',#{self.id},'TagFilter','#{hub.tagging_key}')" }.join(',')
    #ActiveRecord::Base.connection.execute("INSERT INTO taggings (tag_id, taggable_id, taggable_type, tagger_id, tagger_type, context) VALUES #{values}")
    #items.each { |item| item.solr_index }
    items.each do |item|
      new_tagging = item.taggings.build(tag: new_tag, tagger: self, context: hub.tagging_key)

      if new_tagging.valid?
        new_tagging.save!
        item.solr_index
      end
    end

    update(applied: true)
  end
end
