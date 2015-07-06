class AddTagFilter < TagFilter
  def apply(items: items_in_scope)
    deactivate_taggings!(items: items)
    items.find_each do |item|
      new_tagging = item.taggings.build(tag: tag, tagger: self,
                                        context: hub.tagging_key)
      new_tagging.save! if new_tagging.valid?
    end
    self.update_column(:applied, true)
  end
end
