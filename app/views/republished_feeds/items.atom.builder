# frozen_string_literal: true

atom_feed(root_url: hub_republished_feed_url(@hub, @republished_feed), language: 'en-US') do |atom|
  atom.title @republished_feed.title
  atom.updated @republished_feed.updated_at
  atom.generator Tagteam::Application.config.rss_generator

  unless @republished_feed.item_search.nil?
    @republished_feed.item_search.results.each do |item|
      atom.entry(item, url: item.url) do |entry|
        if item.authors.present?
          entry.author do |author|
            author.name item.authors
          end
        end
        if item.contributors.present?
          entry.contributor do |contributor|
            contributor.name item.contributors
          end
        end
        entry.content item.content, type: 'html'
        # Probably not needed.
        #      entry.link( :type => 'text/html', :href => hub_feed_feed_item_url(item.hub_feed_for_hub(@hub.id),item), :rel => 'self' )
        entry.title item.title
        item.all_tags_on(@republished_feed.hub.tagging_key).each do |tag|
          entry.category(term: @republished_feed.hub.tag_prefix.blank? ? tag.name : tag.name_prefixed_with(@republished_feed.hub.tag_prefix), scheme: hub_republished_feed_url(@hub, @republished_feed))
        end
        entry.rights item.rights if item.rights.present?
        entry.summary item.description, type: 'html'
      end
    end
  end
end
