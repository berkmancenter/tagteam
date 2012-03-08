require 'rake_helper'
include RakeHelper

namespace :tagteam do

  desc 'update feeds'
  task :update_feeds => :environment do
    feeds = HubFeed.need_updating
    feeds.each do|hf|
      puts "Updating #{hf.feed.feed_url} "
      hf.feed.update_feed
    end
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

  desc 'test hubs'
  task :test_hubs => :environment do
    u = User.new(:email => 'djcp@cyber.law.harvard.edu', :password => 'testfoobar', :password_confirmation => "testfoobar")
    u.save

    u = User.new(:email => 'peter.suber@gmail.com', :password => 'testpass', :password_confirmation => "testpass")
    u.save

    planet_feeds = %w|
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

  add_example_feeds('Berkman Planet Test Hub', planet_feeds, 'djcp@cyber.law.harvard.edu')

  blogs_feeds = %w|http://blogs.law.harvard.edu/middleeast/feed
http://blogs.law.harvard.edu/businessplans/feed
http://blogs.law.harvard.edu/jkbaumga/feed
http://blogs.law.harvard.edu/doc/feed
http://blogs.law.harvard.edu/yulelog/feed
http://blogs.law.harvard.edu/lamont/feed
http://blogs.law.harvard.edu/adup/feed
http://blogs.law.harvard.edu/dplatechdev/feed
http://blogs.law.harvard.edu/vrm/feed
http://blogs.law.harvard.edu/karolina/feed
http://blogs.law.harvard.edu/dlarochelle/feed
http://blogs.law.harvard.edu/admissions/feed
http://blogs.law.harvard.edu/scotthartley/feed
http://blogs.law.harvard.edu/harvardreview/feed
http://blogs.law.harvard.edu/spaceoccupants/feed
http://blogs.law.harvard.edu/harvardlibraryreads/feed
http://blogs.law.harvard.edu/preserving/feed
http://blogs.law.harvard.edu/hydeblog/feed
http://blogs.law.harvard.edu/yana/feed
http://blogs.law.harvard.edu/youthandmediaalpha/feed
http://blogs.law.harvard.edu/infolaw/feed
http://blogs.law.harvard.edu/clinicalprobono/feed
http://blogs.law.harvard.edu/djcp/feed
http://blogs.law.harvard.edu/houghton/feed
http://blogs.law.harvard.edu/stepno/feed
http://blogs.law.harvard.edu/pamphlet/feed
http://blogs.law.harvard.edu/sulaymanibnqiddees/feed
http://blogs.law.harvard.edu/sj/feed
http://blogs.law.harvard.edu/philg/feed
http://blogs.law.harvard.edu/mjahnke/feed
http://blogs.law.harvard.edu/corpgov/feed
http://blogs.law.harvard.edu/dplaalpha/feed
http://blogs.law.harvard.edu/abinazir/feed
http://blogs.law.harvard.edu/opia/feed
http://blogs.law.harvard.edu/jsinger/feed
http://blogs.law.harvard.edu/jezler/feed
http://blogs.law.harvard.edu/collegeadmissionsstudentblog/feed
http://blogs.law.harvard.edu/kevinguiney/feed
https://twitter.com/statuses/user_timeline/djcp.rss
http://blogs.law.harvard.edu/plap/feed
http://blogs.law.harvard.edu/devivio/feed
http://blogs.law.harvard.edu/herdict/feed
http://blogs.law.harvard.edu/foodpolicyinitiative/feed
http://blogs.law.harvard.edu/mediaberkman/feed
http://blogs.law.harvard.edu/tatar/feed|

  add_example_feeds('Blogs.law test aggregation Hub', blogs_feeds, 'djcp@cyber.law.harvard.edu')

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
