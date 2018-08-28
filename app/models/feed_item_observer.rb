# frozen_string_literal: true
class FeedItemObserver < ActiveRecord::Observer
  # A feed item can get updated with new tags if it gets added by a second feed
  # who tagged it differently, so this needs to run after save, not just
  # create. Actually, after commit:
  # https://github.com/mperham/sidekiq/wiki/Problems-and-Troubleshooting#cannot-find-modelname-with-id12345
  def after_commit(item)
    return unless item.persisted? # We don't need to run if it's been destroyed
    return if item.previous_changes.empty? # Don't run if nothing changed
    item.copy_global_tags_to_hubs unless item.skip_global_tag_copy

    item.hubs.each { |hub| TagFilter.apply_hub_filters(hub, item) }
  end
end
