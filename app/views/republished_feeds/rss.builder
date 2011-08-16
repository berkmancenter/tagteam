xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @republished_feed.title
    xml.description @republished_feed.description
    xml.link republished_feed_url(@republished_feed)
    xml.generator RSS_GENERATOR

    @republished_feed.items.each do |item|
      xml.item do
        xml.title item.title
        xml.description item.content
        xml.pubDate item.date_published.to_s(:rfc822)
        xml.link item.url
        xml.guid item.url
        item.feed_item_tags.each do|fit|
          xml.category fit.tag
        end
      end
    end
  end
end

