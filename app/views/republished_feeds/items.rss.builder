# frozen_string_literal: true

xml.instruct! :xml, version: '1.0'
xml.rss(
  :version => '2.0',
  'xmlns:content' => 'http://purl.org/rss/1.0/modules/content/',
  'xmlns:dc' => 'http://purl.org/dc/elements/1.1/'
) do
  xml.channel do
    xml.title @republished_feed.title
    xml.description @republished_feed.description
    xml.link hub_republished_feed_url(@hub, @republished_feed)
    xml.generator Tagteam::Application.config.rss_generator

    unless @republished_feed.item_search.nil?
      @republished_feed.item_search.results.each do |item|
        xml.item do
          xml.title item.title
          xml.description item.description if item.description.present?
          xml.tag!('content:encoded', item.content) if item.content.present?
          if item.date_published.present?
            xml.pubDate item.date_published.to_s(:rfc822)
          end
          xml.link item.url
          xml.guid item.guid
          xml.author item.authors
          item.all_tags_on(@republished_feed.hub.tagging_key).each do |tag|
            xml.category @republished_feed.hub.tag_prefix.blank? ? tag.name : tag.name_prefixed_with(@republished_feed.hub.tag_prefix)
          end
          xml.tag!('dc:rights', item.rights) if item.rights.present?
          if item.contributors.present?
            xml.tag!('dc:contributor', item.contributors)
          end
        end
      end
    end
  end
end
