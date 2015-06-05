class AddTagFilter < TagFilter
  def apply
    deactivate_taggings!
    items_in_scope.each do |item|
      item.taggings.create(tag: tag, tagger: self, context: hub.tagging_key)
    end
  end
end
