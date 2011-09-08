atom_feed :language => 'en-US' do |atom|
  atom.title @republished_feed.title
  atom.updated @republished_feed.updated_at
  atom.generator RSS_GENERATOR

  @republished_feed.items.each do |item|
    atom.entry( item ) do |entry|
      unless item.author.blank?
        entry.author do |author|
          author.name item.author
        end
      end
      unless item.contributor.blank?
        entry.contributor do |contributor|
          contributor.name item.contributor
        end
      end
      entry.content item.content, :type => 'html'
      entry.link item.url 
      entry.title item.title
      item.feed_item_tags.each do |icat|
        entry.category(:term => icat, :scheme => republished_feed_url(@republished_feed))
      end
      entry.rights item.rights
      entry.summary item.description, :type => 'html'
      entry.updated(item.last_updated.strftime("%Y-%m-%dT%H:%M:%SZ")) 
      entry.published(item.date_published.strftime("%Y-%m-%dT%H:%M:%SZ")) 
    end
  end
end
