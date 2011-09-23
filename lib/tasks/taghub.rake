namespace :taghub do

  desc 'update feeds'
  task :update_feeds => :environment do
    @feeds = Feed.need_updating
  end

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

  desc 'test feed sources'
  task :test_feed_sources => :environment do
    feeds = %w|
http://fringethoughts.wordpress.com/feed/
http://blogs.law.harvard.edu/andresmh/feed/
http://andyontheroad.wordpress.com/feed/
http://mako.cc/copyrighteous/?flav=atom
http://cyber.law.harvard.edu/news/feed
http://www.betsym.org/blog/feed/
http://crcs.seas.harvard.edu/feed/
http://blogs.law.harvard.edu/nesson/feed/
http://www.chillingeffects.org/weather.xml
http://blogs.law.harvard.edu/niftyc/feed
http://feeds.feedburner.com/CitizenMediaLawProject
http://childrenshospitalblog.org/category/claire-mccarthy-md/feed/
http://www.shirky.com/weblog/feed/
http://blogs.law.harvard.edu/cyberlawclinic/feed/
http://www.guardian.co.uk/profile/dangillmor/rss
http://mediactive.com/feed/
http://www.hyperorg.com/blogger/feed/
http://d3nten.com/feed/
http://blogs.law.harvard.edu/digitalnatives/feed/
http://theclatterofkeys.tumblr.com/rss
http://www.esztersblog.com/feed/
http://www.ethanzuckerman.com/blog/feed/
http://blogs.law.harvard.edu/mossing/feed/
http://cyber.law.harvard.edu/views/minifeed/913/feed
http://cyber.law.harvard.edu/views/minifeed/1112/feed
http://blogs.law.harvard.edu/hroberts/feed/
http://harry-lewis.blogspot.com/feeds/posts/default?alt=rss
http://www.herdict.org/blog/feed/
http://feeds.feedburner.com/jakeshapiro/KalU
http://cyber.law.harvard.edu/views/minifeed/912/feed
http://www.stanford.edu/group/shl/cgi-bin/drupal/?q=blog/9/feed
http://blogs.law.harvard.edu/palfrey/feed/
http://futureoftheinternet.org/feed
http://reagle.org/joseph/blog/?flav=atom
http://demartin.polito.it/blog/feed
http://spoudaiospaizen.net/feed/
http://blogs.law.harvard.edu/lawlab/feed/
http://www.matthewhindman.com/index.php/component/option,com_rss/feed,RSS2.0/no_html,1/
http://www.mediacloud.org/blog/feed/
http://blogs.law.harvard.edu/mediaberkman/feed/
http://www.miriammeckel.de/feed/
http://opennet.net/blog/feed
http://feeds.feedburner.com/prxblog?format=xml
http://blogs.law.harvard.edu/vrm/feed/
http://publius.cc/essays/rss
http://diy2.usc.edu/wordpress/?feed=rss2
http://blogs.law.harvard.edu/pamphlet/feed/
http://blogs.law.harvard.edu/trunk/feed/
http://blogs.law.harvard.edu/surveillance/feed/
http://blog.pinang.org/feed/rss2
http://blogs.law.harvard.edu/ugasser/feed/
http://wayneandwax.com/?feed=rss2
http://wendy.seltzer.org/blog/feed
http://technosociology.org/?feed=rss2
http://cyber.law.harvard.edu/views/minifeed/740/feed
http://metalab.harvard.edu/feed/|

  h = Hub.find_or_create_by_title(:title => 'Auto feed test hub')
  u = User.find_by_email('admin@example.com')

  u.has_role!(:owner, h)
  u.has_role!(:creator, h)

  feeds.each do|feed|
    f = Feed.find_or_initialize_by_feed_url(feed)
    puts "Getting: #{feed}"

    if f.valid?
      f.save
      u.has_role!(:owner, f)
      u.has_role!(:creator, f)

      hf = HubFeed.new
      hf.hub = h
      hf.feed = f

      if hf.valid?
        hf.save
        u.has_role!(:owner, hf)
        u.has_role!(:creator, hf)
      else 
        puts "Hub feed Error: #{hf.errors.inspect}"
      end
    else
      puts "Feed Error: #{f.errors.inspect}"
    end
  end


  end

end
