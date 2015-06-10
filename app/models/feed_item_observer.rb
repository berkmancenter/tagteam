class FeedItemObserver < ActiveRecord::Observer
  def after_create(item)
    return if item.skip_global_tag_copy
    item.copy_global_tags_to_hubs
  end
end
