class ReindexFeedRetrievals
  @queue = :reindexer

  def self.display_name
    'Reindexing feed updates'
  end

  def self.perform(feed_id)
    FeedRetrieval.where(:feed_id => feed_id).solr_index(:batch_size => 500, :batch_commit => false, :include => [:hubs, :feed])
  end

end
