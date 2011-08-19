namespace :taghub do

  desc 'clean up orphaned items'
  task :clean_orphan_items => :environment do
    conn = ActiveRecord::Base.connection

    results = conn.execute('select id from feed_items where id not in(select feed_item_id from feed_items_feeds group by feed_item_id)')
    results.each do|row|
      FeedItem.destroy(row['id'])
    end

    results = conn.execute("select id from feed_item_tags where id not in(select feed_item_tag_id from feed_item_tags_feed_items group by feed_item_tag_id)")
    results.each do|row|
      FeedItemTag.destroy(row['id'])
    end

    results = conn.execute("select id from feeds where id not in(select feed_id from hub_feeds group by feed_id)")
    results.each do|row|
      Feed.destroy(row['id'])
    end
  end

  desc 'Parser tests'
  task :parser_tests => :environment do
    ['djcp_code.rss','djcp.rss','doc.atom','djcp_delicious.rss','oa.africa.rss'].each do|rss_file|
      puts "Feed is: #{rss_file}"
      file = File.read("public/_tests/#{rss_file}")
    #  feed = FeedNormalizer::FeedNormalizer.parse(file)
    #  puts "Title is: #{feed.title}"
    #  puts "Parser is: #{feed.parser}"
      
      feed = RSS::Parser.parse(file,false)

      puts "From RSS::Parser: " + feed.channel.title
      puts "From RSS::Parser: " + feed.channel.description

      puts

    end


  end

end
