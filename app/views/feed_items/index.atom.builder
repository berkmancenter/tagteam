atom_feed(:root_url => hub_hub_feed_url(@hub,@hub_feed), :language => 'en-US') do |atom|
  atom.title @hub_feed.display_title
  atom.updated @feed_items.first.updated_at
  atom.generator Tagteam::Application.config.rss_generator

  @feed_items.each do |item|
    atom.entry( item , :url => item.url ) do |entry|
      unless item.authors.blank?
        entry.author do |author|
          author.name item.authors
        end
      end
      unless item.contributors.blank?
        entry.contributor do |contributor|
          contributor.name item.contributors
        end
      end
      entry.content item.content, :type => 'html'
# Probably not needed.
#      entry.link( :type => 'text/html', :href => hub_feed_feed_item_url(item.hub_feed_for_hub(@hub.id),item), :rel => 'self' )
      entry.title item.title
      item.tags_on(@hub_feed.hub.tagging_key).each do |tag|
        entry.category(:term => (@hub_feed.hub.tag_prefix.blank?) ? tag.name : tag.name_prefixed_with(@hub_feed.hub.tag_prefix), :scheme => hub_hub_feed_url(@hub,@hub_feed))
      end
      unless item.rights.blank?
        entry.rights item.rights
      end
      entry.summary item.description, :type => 'html'
    end
  end
end
