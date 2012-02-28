atom_feed(:root_url => hub_republished_feed_url(@hub,@republished_feed), :language => 'en-US', :instruct => { 'xml-stylesheet' => {:type => 'text/xsl', :media => 'screen', :href => root_path() + 'stylesheets/atom.xsl'}}) do |atom|
  atom.title @republished_feed.title
  atom.updated @republished_feed.updated_at
  atom.generator RSS_GENERATOR

  @republished_feed.item_search.results.each do |item|
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
      item.tag_list_on(@republished_feed.hub.tagging_key).each do |tag|
        entry.category(:term => (@republished_feed.hub.tag_prefix.blank?) ? tag : "#{@republished_feed.hub.tag_prefix}#{tag}", :scheme => hub_republished_feed_url(@hub,@republished_feed))
      end
      unless item.rights.blank?
        entry.rights item.rights
      end
      entry.summary item.description, :type => 'html'
    end
  end
end
