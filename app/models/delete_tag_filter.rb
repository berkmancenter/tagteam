class DeleteTagFilter < TagFilter
  def apply(items: items_in_scope)
    deactivate_taggings!(items: items)
    self.update_column(:applied, true)
  end
end
