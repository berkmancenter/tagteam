
# frozen_string_literal: true
['djcp_code.rss', 'djcp.rss', 'doc.atom', 'djcp_delicious.rss', 'oa.africa.rss'].each do |rss_file|
  puts "Feed is: #{rss_file}"
  file = File.read("public/_tests/#{rss_file}")
  #  feed = FeedNormalizer::FeedNormalizer.parse(file)
  #  puts "Title is: #{feed.title}"
  #  puts "Parser is: #{feed.parser}"

  #  feed = RSS::Parser.parse(file,false)
  feed = FeedAbstract::Feed.new(file)

  puts feed.class.to_s
end
