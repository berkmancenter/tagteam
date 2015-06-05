describe ModifyTagFilter do
  # We create a feed modify tag filter to change 'tag1' to 'tag2'
  # All 'tag1' taggings get deactivated
  # We create a hub modify tag filter to change 'tag1' to 'tag3'
  # We remove the 'tag1' to 'tag2' filter
  # All 'tag1' taggings get reactivated
  # We reapply all later filters
  #
  # An item comes in from an external feed with tags 'tag1' and 'tag2'.
  # We add a hub filter that changes 'tag1' to 'tag2'
  # Both taggings on the item should be deactivated, as the 'tag2' tagging
  # should now be owned by the filter, not the external feed.
  #
  # An item comes in from an external feed with tag 'tag2'.
  # We add a hub filter that changes 'tag1' to 'tag2'
  # We shouldn't touch the external feed's tagging of 'tag2'.
end
