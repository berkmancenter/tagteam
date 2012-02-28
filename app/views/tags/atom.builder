atom_feed(:root_url => hub_tag_show_url(@hub,@tag.name), :language => 'en-US') do |atom|
  atom.title "Items tagged with #{@tag.name} in #{@hub.title}"
  atom.updated @feed_items.first.updated_at
  atom.generator RSS_GENERATOR

  @feed_items.each do |item|
    atom.entry( item, :url => item.url ) do |entry|
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
#      entry.link( :type => 'text/html', :href => hub_feed_feed_item_url(item.hub_feed_for_hub(@hub.id),item), :rel => 'self' )
      entry.title item.title
      item.tag_list_on(@hub.tagging_key).each do |tag|
        entry.category(:term => (@hub.tag_prefix.blank?) ? tag : "#{@hub.tag_prefix}#{tag}", :scheme => hub_tag_path(@hub,@tag))
      end
      unless item.rights.blank?
        entry.rights item.rights
      end
      entry.summary item.description, :type => 'html'
    end
  end
end
