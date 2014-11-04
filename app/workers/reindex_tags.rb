class ReindexTags
  include Sidekiq::Worker
  sidekiq_options :queue => :reindexer

  def self.display_name
    "Reindexing tags"
  end

  def perform
    ActsAsTaggableOn::Tag.solr_index(:batch_size => 500, :include => :taggings, :batch_commit => false)
  end

end
