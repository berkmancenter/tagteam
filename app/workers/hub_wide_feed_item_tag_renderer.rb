class HubWideFeedItemTagRenderer
  include Sidekiq::Worker
  sidekiq_options :queue => :renderer

  def self.display_name
    'Updating all items effected by a change in a tag'
  end

  def perform(hub_id, tag_id = nil)
    # Here is where we'll update all the items affected by this change in this feed.
    # if hub_tag_filter_id is nil, then this was a deleted filter and we should change our behavior accordingly.

    hub = Hub.find(hub_id)
    feed_item_ids = []
    if tag_id.nil?
      # Act on all items
      feed_items = FeedItem.includes(:feeds,:taggings) \
          .where({'feeds.id' => hub.feeds.collect{|f| f.id}})
    else
      # act only on items with the tag of interest.
      feed_items = FeedItem.includes(:feeds,:taggings).where(
          'feeds.id' => hub.feeds.collect{|f| f.id},
          'taggings.tag_id' => tag_id,
          'taggings.context' => 'tags'
      )
    end

    ac = ActionController::Base.new

    # Re-render tags.
    feed_items.find_each do |fi|
      feed_item_ids << fi.id
      fi.render_filtered_tags_for_hub(hub)
      fi.skip_tag_indexing_after_save = true
      fi.save
    end

    #batch reindex tags.
    ActsAsTaggableOn::Tag.includes(:taggings).where(
        'taggings.taggable_type' => 'FeedItem',
        'taggings.taggable_id' => feed_item_ids,
    ).solr_index(:batch_size => 500, :batch_commit => false)

    #batch expire caches.
    feed_items.find_each do|fi|
      key = "feed-item-tag-list-#{hub.id}-#{fi.id}"
      ac.expire_fragment(key)
    end

  end

end
