# frozen_string_literal: true
class ReindexFeedRetrievals
  include Sidekiq::Worker
  sidekiq_options queue: :reindexer

  def self.display_name
    'Reindexing feed updates'
  end

  def perform(feed_id)
    FeedRetrieval.where(feed_id: feed_id).solr_index(batch_size: 500, batch_commit: false, include: [:hubs, :feed])
  end
end
