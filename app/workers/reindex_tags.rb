class ReindexTags
  @queue = :reindexer

  def self.display_name
    "Reindexing tags"
  end

  def self.perform(tagging_key = nil)
    ActsAsTaggableOn::Tag.solr_index(:batch_size => 500, :include => :taggings, :batch_commit => false)
    Sunspot.commit
    if tagging_key
      hub = Hub.all.detect {|h| h.tagging_key.to_s == tagging_key }
      TagCountUpdater.perform [hub]
    end
  end
end
