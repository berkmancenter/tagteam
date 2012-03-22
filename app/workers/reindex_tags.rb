class ReindexTags
  @queue = :reindex_tags

  def self.display_name
    "Reindexing tags"
  end

  def self.perform
    ActsAsTaggableOn::Tag.reindex
  end

end
