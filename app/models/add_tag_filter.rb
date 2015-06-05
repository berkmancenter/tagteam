class AddTagFilter < TagFilter
  def apply(items: items_in_scope)
    deactivate_taggings!(items: items)
    items.each do |item|
      item.taggings.create(tag: tag, tagger: self, context: hub.tagging_key)
    end
  end
end
