# frozen_string_literal: true

class AddTagFilter < TagFilter
  def apply(item_ids = [])
    items = item_ids.any? ? FeedItem.find(item_ids) :
      scope.taggable_items

    # This does not deal with duplicates
    deactivate_taggings!(items.map(&:id))

    # Because the above doesn't deactivate duplicates, we can't do a mass insert
    items.each do |item|
      new_tagging = item.taggings.build(tag: tag, tagger: self,
                                        context: hub.tagging_key)
      if new_tagging.valid?
        new_tagging.save!
        item.solr_index
      end
    end

    update_column(:applied, true)
  end

  def simulate(tag_list)
    tag_list.include?(tag.name) ? tag_list : tag_list + [tag.name]
  end

  def filters_before
    []
  end

  def filters_after
    subsequent = hub.all_tag_filters.where('tag_id = ? AND updated_at > ?',
                                           tag.id, updated_at).first
    subsequent ? [subsequent] + subsequent.filters_after : []
  end

  def tag_changes
    { tags_added: [tag] }
  end
end
