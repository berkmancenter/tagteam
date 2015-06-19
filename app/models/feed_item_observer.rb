class FeedItemObserver < ActiveRecord::Observer
  # A feed item can get updated with new tags if it gets added by a second feed
  # who tagged it differently, so this needs to run after save, not just
  # create. Actually, after commit:
  # https://github.com/mperham/sidekiq/wiki/Problems-and-Troubleshooting#cannot-find-modelname-with-id12345
  def after_commit(item)
    item.copy_global_tags_to_hubs unless item.skip_global_tag_copy
    FeedItem.delay.apply_tag_filters(item.id)
  end
end
