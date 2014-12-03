module HubsHelper
  def limit_html(html, limit)
    require 'nokogiri'
    html = html[0..limit]
    Nokogiri::HTML::fragment(html).to_xml
  end
end
