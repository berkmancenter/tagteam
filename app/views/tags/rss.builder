xml.instruct! :xml, :version => "1.0" 
xml.instruct! 'xml-stylesheet', :type => 'text/xsl', :media => 'screen', :href => root_path() + 'stylesheets/rss.xsl'
xml.rss(
  :version => '2.0',
  'xmlns:content' => 'http://purl.org/rss/1.0/modules/content/',
  'xmlns:dc' => 'http://purl.org/dc/elements/1.1/'
  ) do
  xml.channel do
    xml.title "Items tagged with #{@tag.name} in #{@hub.title}"
    xml.description "Items tagged with #{@tag.name} in #{@hub.title}"
    xml.link hub_tag_path(@hub,@tag)
    xml.generator RSS_GENERATOR

    @feed_items.each do |item|
      xml.item do
        xml.title item.title
        unless item.description.blank?
          xml.description item.description
        end
        unless item.content.blank?
          xml.tag!('content:encoded', item.content)
        end
        unless item.date_published.blank?
          xml.pubDate item.date_published.to_s(:rfc822)
        end
        xml.link item.url
        xml.guid item.guid
        xml.author item.authors
        item.tag_list_on(@hub.tagging_key).each do|tag|
          xml.category (@hub.tag_prefix.blank?) ? tag : "#{@hub.tag_prefix}#{tag}"
        end
        unless item.rights.blank?
          xml.tag!('dc:rights', item.rights)
        end
        unless item.contributors.blank?
          xml.tag!('dc:contributor', item.contributors)
        end
      end
    end
  end
end
