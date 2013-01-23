require 'rake_helper'
include RakeHelper

namespace :tagteam do

  desc 'auto import feeds from json'
  task :auto_import_from_json, [:json_url, :hub_title, :owner_email] => :environment do |t,args|

    include FeedUtilities

    response = fetch(args[:json_url])
    feeds = ActiveSupport::JSON.decode(response.body)

    add_example_feeds(args[:hub_title], feeds, args[:owner_email])
  end

  desc 'dump documentation'
  task :dump_documentation => :environment do
    f = File.open("#{Rails.root}/db/documentation.yml", 'w')
    f.write(Documentation.all.to_yaml)
    f.close
  end

  desc 'expire file cache'
  task :expire_file_cache => :environment do
    ExpireFileCache.perform
  end

  desc 'update feeds'
  task :update_feeds => :environment do
    UpdateFeeds.perform
  end

  desc 'clean up orphaned items'
  task :clean_orphan_items => :environment do
    conn = ActiveRecord::Base.connection

    results = conn.execute("select id from feeds where id not in(select feed_id from hub_feeds group by feed_id)")
    puts "Destroying Feeds #{results.collect{|r| r['id']}.join(',')}"
    Feed.destroy(results.collect{|r| r['id']})

    results = conn.execute('select id from feed_items where id not in(select feed_item_id from feed_items_feeds group by feed_item_id)')
    puts "Destroying FeedItems #{results.collect{|r| r['id']}.join(',')}"
    FeedItem.destroy(results.collect{|r| r['id']})

    Role.includes(:authorizable).where('authorizable_id is not null').all.each do|r|
      if r.authorizable.blank?
        puts "Destroying Role #{r.id}"
        Role.destroy(r.id)
      end
    end
  
  end

  desc 'tiny test hubs'
  task :tiny_test_hubs => :environment do
      u = User.new(:email => 'djcp@cyber.law.harvard.edu', :password => 'testfoobar', :password_confirmation => "testfoobar")
      u.save

      planet_feeds = %w|
http://cyber.law.harvard.edu/news/feed
http://childrenshospitalblog.org/category/claire-mccarthy-md/feed/
http://www.shirky.com/weblog/feed/
http://reagle.org/joseph/blog/?flav=atom
http://www.matthewhindman.com/index.php/component/option,com_rss/feed,RSS2.0/no_html,1/
http://www.mediacloud.org/blog/feed/|

    add_example_feeds('Berkman Planet Test Hub', planet_feeds, 'djcp@cyber.law.harvard.edu')

  end

  desc 'test hubs'
  task :test_hubs => :environment do
    u = User.new(:email => 'djcp@cyber.law.harvard.edu', :password => 'testfoobar', :password_confirmation => "testfoobar")
    u.save

    u = User.new(:email => 'peter.suber@gmail.com', :password => 'testpass', :password_confirmation => "testpass")
    u.save

    planet_feeds = %w|
http://fringethoughts.wordpress.com/feed/
http://blogs.law.harvard.edu/andresmh/feed
http://andyontheroad.wordpress.com/feed
http://mako.cc/copyrighteous/?flav=atom
http://cyber.law.harvard.edu/news/feed
http://www.betsym.org/blog/feed/
http://crcs.seas.harvard.edu/feed/
http://blogs.law.harvard.edu/nesson/feed
http://www.chillingeffects.org/weather.xml
http://blogs.law.harvard.edu/niftyc/feed
http://feeds.feedburner.com/CitizenMediaLawProject
http://childrenshospitalblog.org/category/claire-mccarthy-md/feed/
http://www.shirky.com/weblog/feed/
http://blogs.law.harvard.edu/cyberlawclinic/feed
http://www.guardian.co.uk/profile/dangillmor/rss
http://mediactive.com/feed/
http://www.hyperorg.com/blogger/feed/
http://d3nten.com/feed/
http://blogs.law.harvard.edu/digitalnatives/feed
http://theclatterofkeys.tumblr.com/rss
http://www.esztersblog.com/feed/
http://www.ethanzuckerman.com/blog/feed/
http://blogs.law.harvard.edu/mossing/feed
http://cyber.law.harvard.edu/views/minifeed/913/feed
http://cyber.law.harvard.edu/views/minifeed/1112/feed
http://blogs.law.harvard.edu/hroberts/feed
http://harry-lewis.blogspot.com/feeds/posts/default?alt=rss
http://www.herdict.org/blog/feed/
http://feeds.feedburner.com/jakeshapiro/KalU
http://cyber.law.harvard.edu/views/minifeed/912/feed
http://www.stanford.edu/group/shl/cgi-bin/drupal/?q=blog/9/feed
http://blogs.law.harvard.edu/palfrey/feed
http://futureoftheinternet.org/feed
http://reagle.org/joseph/blog/?flav=atom
http://demartin.polito.it/blog/feed
http://spoudaiospaizen.net/feed/
http://blogs.law.harvard.edu/lawlab/feed
http://www.matthewhindman.com/index.php/component/option,com_rss/feed,RSS2.0/no_html,1/
http://www.mediacloud.org/blog/feed/
http://blogs.law.harvard.edu/mediaberkman/feed
http://www.miriammeckel.de/feed/
http://opennet.net/blog/feed
http://feeds.feedburner.com/prxblog?format=xml
http://blogs.law.harvard.edu/vrm/feed
http://publius.cc/essays/rss
http://diy2.usc.edu/wordpress/?feed=rss2
http://blogs.law.harvard.edu/pamphlet/feed
http://blogs.law.harvard.edu/trunk/feed
http://blogs.law.harvard.edu/surveillance/feed
http://blog.pinang.org/feed/rss2
http://blogs.law.harvard.edu/ugasser/feed
http://wayneandwax.com/?feed=rss2
http://wendy.seltzer.org/blog/feed
http://technosociology.org/?feed=rss2
http://cyber.law.harvard.edu/views/minifeed/740/feed
http://metalab.harvard.edu/feed|

  add_example_feeds('Berkman Planet Test Hub', planet_feeds, 'djcp@cyber.law.harvard.edu')

  oa_feeds = %w|http://www.connotea.org/rss/tag/oa.new 
http://www.connotea.org/rss/tag/oa.mandates
http://www.connotea.org/rss/tag/oa.policies
http://www.connotea.org/rss/tag/oa.repositories
http://www.connotea.org/rss/tag/oa.journals
http://www.connotea.org/rss/tag/oa.green
http://www.connotea.org/rss/tag/oa.gold
http://www.connotea.org/rss/tag/oa.data
http://www.connotea.org/rss/tag/oa.books
http://www.connotea.org/rss/tag/oa.rwa
http://www.connotea.org/rss/tag/oa.frpaa
http://www.connotea.org/rss/tag/oa.boycotts
http://www.connotea.org/rss/tag/oa.petitions
http://www.connotea.org/rss/tag/oa.pledges
http://www.connotea.org/rss/tag/oa.elsevier
http://www.connotea.org/rss/tag/oa.usa
http://www.connotea.org/rss/tag/oa.europe
http://www.connotea.org/rss/tag/oa.south|

  add_example_feeds('Open Access', oa_feeds, 'peter.suber@gmail.com')

  end

end
