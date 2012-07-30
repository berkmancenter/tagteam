class ImportFeedItems
  @queue = :importer

  def self.display_name
    'Importing items from an uploaded file'
  end

  def self.perform(hub_feed_id,user_id,file_name,type)
    hub_feed = HubFeed.find(hub_feed_id)
    feed = hub_feed.feed
    errors = []
    items = []
    current_user = User.find(user_id)

    if type == 'connotea_rdf'
      importer = Tagteam::Importer::Connotea.new(file_name)
    elsif type == 'delicious'
      importer = Tagteam::Importer::Delicious.new(file_name)
    end

    items = importer.parse_items
    items.each do|item|
      feed_item = FeedItem.find_or_initialize_by_url(item[:url])
      [:title, :url, :guid, :authors, :contributors, :description, :content, :rights, :date_published, :last_updated].each do|col|
        feed_item.send(%Q|#{col}=|, item[col])
      end
      feed_item.tag_list = [feed_item.tag_list, item[:tag_list].collect{|t| t.downcase[0,255].gsub(/,/,'_')}].flatten.compact.join(',')

      if feed_item.save
        feed_item.accepts_role!(:owner, current_user)
        feed_item.accepts_role!(:creator, current_user)
        if feed.feed_items.blank? || ! feed.feed_items.include?(feed_item)
          feed.feed_items << feed_item
        end
      else
        errors << feed_item.errors.full_messages.join('<br/>')
      end
    end
    feed.save
    Resque.enqueue(HubFeedFeedItemTagRenderer, hub_feed.id)
  end

end
