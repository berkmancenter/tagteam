class FeedItemObserver < ActiveRecord::Observer
  def after_create(item)
    item.copy_global_tags_to_hubs unless item.skip_global_tag_copy
    FeedItem.delay.apply_tag_filters(item.id)
  end
end
