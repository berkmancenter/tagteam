# frozen_string_literal: true
class DeleteTagFilter < TagFilter
  def apply(item_ids = [])
    if item_ids.any?
      item_ids &= scope.taggable_items.pluck(:id)
      items = FeedItem.where(id: item_ids).tagged_with(tag.name, on: hub.tagging_key)
    else
      items = scope.taggable_items.tagged_with(tag.name, on: hub.tagging_key)
    end

    deactivate_taggings!(items.map(&:id))
    update_column(:applied, true)
  end

  def simulate(tag_list)
    tag_list.reject { |t| t == tag.name }
  end

  def filters_before
    previous = hub.all_tag_filters.where(
      '(tag_id = :tag_id OR new_tag_id = :tag_id) AND updated_at < :updated_at',
      tag_id: tag.id, updated_at: updated_at
    ).last
    previous ? previous.filters_before + [previous] : []
  end

  def filters_after
    []
  end

  def tag_changes
    { tags_deleted: [tag] }
  end
end
