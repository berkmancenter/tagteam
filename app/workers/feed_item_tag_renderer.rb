class FeedItemTagRenderer
  @queue = :renderer

  def self.display_name
    'Updating tag facets for a feed item'
  end

  def self.perform(feed_item_id)
    fi = FeedItem.find(feed_item_id)

    ac = ActionController::Base.new
    fi.hubs.each do|hub|
      fi.render_filtered_tags_for_hub(hub)
      fi.skip_tag_indexing_after_save = true
      fi.save
    end

    #batch reindex tags.
    ActsAsTaggableOn::Tag.includes(:taggings).where('taggings.taggable_type' => 'FeedItem', 'taggings.taggable_id' => fi.id).solr_index(:batch_size => 500, :batch_commit => false)

    #batch expire caches.
    fi.hubs.each do|hub|
      key = "feed-item-tag-list-#{hub.id}-#{fi.id}"
      ac.expire_fragment(key)
    end

    Sunspot.commit

    fi.hubs.each do |h|
      h.update_tag_count
    end  
    Resque.enqueue(TagCountUpdater, fi.hubs)   
   end
end
