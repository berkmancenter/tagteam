class DeleteTagFilter < TagFilter
  def apply
    deactivate_taggings!
  end
end
