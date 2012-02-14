class ReindexTags
  @queue = :reindex_tags

  def self.perform
    ActsAsTaggableOn::Tag.reindex
  end

end
