atom_feed(:root_url => hub_url(@hub), :language => 'en-US') do |atom|
  atom.title @hub.title
  atom.updated (@search.results.blank?) ? Time.now : @search.results.first.updated_at
  atom.generator Tagteam::Application.config.rss_generator

  @search.results.each do |item|
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
      (item.all_tags_on(@hub.tagging_key) - @hub.deprecated_tags).each do |tag|
        entry.category(:term => (@hub.tag_prefix.blank?) ? tag.name : tag.name_prefixed_with(@hub.tag_prefix), :scheme => hub_url(@hub))
      end
      unless item.rights.blank?
        entry.rights item.rights
      end
      entry.summary item.description, :type => 'html'
    end
  end
end
