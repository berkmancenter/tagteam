class FeedItemObserver < ActiveRecord::Observer
  # A feed item can get updated with new tags if it gets added by a second feed
  # who tagged it differently, so this needs to run after save, not just
  # create. Actually, after commit:
  # https://github.com/mperham/sidekiq/wiki/Problems-and-Troubleshooting#cannot-find-modelname-with-id12345
  def after_commit(item)
    return unless item.persisted? # We don't need to run if it's been destroyed
    item.copy_global_tags_to_hubs unless item.skip_global_tag_copy
    Hub.apply_all_tag_filters_to_item_async(item)
  end
end
