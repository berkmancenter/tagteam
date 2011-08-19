require 'rss'
require File.expand_path(File.join(File.dirname(__FILE__), "feed", "abstract"))
#require 'feed/abstract'

['djcp_code.rss','djcp.rss','doc.atom','djcp_delicious.rss','oa.africa.rss'].each do|rss_file|
  puts "Feed is: #{rss_file}"
  file = File.read("public/_tests/#{rss_file}")
  #  feed = FeedNormalizer::FeedNormalizer.parse(file)
  #  puts "Title is: #{feed.title}"
  #  puts "Parser is: #{feed.parser}"

#  feed = RSS::Parser.parse(file,false)
  feed = Feed::Abstract.parse(file)

  puts "#{feed.class}"

  if feed.class == RSS::Atom::Feed
    puts "From RSS::Atom::Feed: " + feed.title.content
    puts "From RSS::Atom::Feed: " + feed.subtitle.content

    feed.items.each do|entry|
      puts entry.title.content
    end

  elsif feed.class == RSS::RDF

    puts "From RSS::RDF: " + feed.channel.title
    puts "From RSS::RDF: " + feed.channel.description
    feed.items.each do|entry|
      puts entry.title
    end

  else
    puts "From RSS::Rss: " + feed.channel.title
    puts "From RSS::Rss: " + feed.channel.description
    feed.items.each do|entry|
      puts entry.title
    end
  end
  puts
end
