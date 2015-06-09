class AddTagFilter < TagFilter
  def apply(items: items_in_scope)
    deactivate_taggings!(items: items)
    items.each do |item|
      new_tagging = item.taggings.build(tag: tag, tagger: self,
                                        context: hub.tagging_key)
      new_tagging.save! if new_tagging.valid?
    end
    self.update_attribute(:applied, true)
  end
end
