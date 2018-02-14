# frozen_string_literal: true

atom_feed(root_url: @home_url, language: 'en-US') do |atom|
  atom.title "Items tagged by #{@user.username} in #{@hub.title}"
  atom.updated @feed_items.blank? ? Time.now : @feed_items.first.updated_at
  atom.generator Tagteam::Application.config.rss_generator

  @feed_items.each do |item|
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
      #      entry.link( :type => 'text/html', :href => hub_feed_feed_item_url(item.hub_feed_for_hub(@hub.id),item), :rel => 'self' )
      entry.title item.title
      item.all_tags_on(@hub.tagging_key).each do |tag|
        entry.category(term: @hub.tag_prefix.blank? ? tag.name : tag.name_prefixed_with(@hub.tag_prefix), scheme: @home_url)
      end
      entry.rights item.rights if item.rights.present?
      entry.summary item.description, type: 'html'
    end
  end
end
