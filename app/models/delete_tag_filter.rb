class DeleteTagFilter < TagFilter
  def apply(items: items_in_scope)
    items = filter_to_scope(items)
    deactivate_taggings!(items: items)
    self.update_column(:applied, true)
  end

  def simulate(tag_list)
    tag_list.reject{|t| t == tag.name }
  end

  def filters_before
    previous = hub.all_tag_filters.where(
      '(tag_id = :tag_id OR new_tag_id = :tag_id) AND updated_at < :updated_at',
      { tag_id: tag.id, updated_at: updated_at}).last
    previous ? previous.filters_before + [previous] : []
  end

  def filters_after
    []
  end
end
