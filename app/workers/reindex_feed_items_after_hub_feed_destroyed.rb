# frozen_string_literal: true

class ReindexFeedItemsAfterHubFeedDestroyed
  include Sidekiq::Worker
  sidekiq_options queue: :reindexer

  def self.display_name
    'Reindexing feed items in bulk after a hub feed was removed'
  end

  def perform(feed_item_ids = [], tagging_key)
    # It's OK to delete rather than destroy here because we're not using "remove_unused" (which is run via an after_destroy trigger) and this makes it run hella fast.
    ActsAsTaggableOn::Tagging.delete_all(context: tagging_key, taggable_type: 'FeedItem', taggable_id: feed_item_ids)

    FeedItem.where(id: feed_item_ids).solr_index(batch_size: 500, include: %i[taggings tags hub_feeds hubs feeds], batch_commit: false)

    Sidekiq::Client.enqueue(ReindexTags)
  end
end
