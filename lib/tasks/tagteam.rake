require 'rake_helper'
include RakeHelper

class HubTagFilter < ActiveRecord::Base
end
class HubFeedTagFilter < ActiveRecord::Base
end
class HubFeedItemTagFilter <ActiveRecord::Base
end

namespace :tagteam do
  desc 'Migrate to new tag system'
  task :migrate_tagging => :environment do |t|
    puts 'Make sure sunspot is disabled, or this will be really slow.'

    puts 'Destroying Hub 31'
    Hub.find(31).destroy unless Hub.where(id: 31).empty?
    Rake::Task['tagteam:clean_orphan_items'].invoke # Took about 45 mins

    class NewTagging < ActiveRecord::Base
      establish_connection :new_production
      self.table_name = 'taggings'
      attr_accessible :id, :taggable_id, :taggable_type, :tag_id, :tagger_id,
        :tagger_type, :context, :created_at
    end

    ## Do the global taggings first
    # Delete the taggings from the global context that have a matching tagging
    # in the hub context with an owner. Those are from bookmarkers.
    current_db = ActiveRecord::Base.connection
    results = current_db.execute("SELECT t1.id FROM taggings AS t1 JOIN
                                 taggings AS t2 ON t1.taggable_id
                                 = t2.taggable_id AND t1.tag_id = t2.tag_id
                                 WHERE t1.context = 'tags' AND t2.context !=
                                   'tags' AND t2.tagger_id IS NOT NULL;")
    delete_ids = results.map{ |r| r['id'] }
    puts "Deleting #{delete_ids.count} bookmarker taggings from global context"
    ActsAsTaggableOn::Tagging.delete(delete_ids)


    # Find an owner for all remaining taggings - really just the first feed.
    # This will set a feed in some undetermined way, which is fine.
    puts "Adding tagging owners to global tags"
    current_db.execute("UPDATE taggings SET tagger_id
    = feed_items_feeds.feed_id, tagger_type = 'Feed' FROM feed_items_feeds
    WHERE feed_items_feeds.feed_item_id = taggings.taggable_id AND
                       taggings.context = 'tags' AND taggings.tagger_id IS NULL;")

    # Migrate over all the remaining taggings in the global context.
    puts "Migrating global taggings over to new prod"
    NewTagging.delete_all
    bar = ProgressBar.new(ActsAsTaggableOn::Tagging.where(context: 'tags').count)
    ActsAsTaggableOn::Tagging.where(context: 'tags').each do |tagging|
      NewTagging.create(tagging.attributes)
      tagging.delete
      bar.increment!
    end
    
    ## Now do the hub taggings
    # Migrate all filters over.
    def translate_filter(filter, scope)
      new_filter = TagFilter.create(
        hub: filter.hub,
        scope: scope,
        tag: filter.filter.tag,
        new_tag: filter.filter.new_tag,
        type: filter.filter_type,
        applied: true,
        created_at: filter.created_at,
        updated_at: filter.updated_at
      )

      filter.owners.each do |owner|
        owner.has_role! :owner, new_filter
      end
      filter.creators.each do |creator|
        creator.has_role! :creator, new_filter
      end
    end

    HubTagFilter.unscoped.order('updated_at ASC').each do |filter|
      translate_filter(filter, filter.hub)
      filter.destroy
    end

    HubFeedTagFilter.unscoped.order('updated_at ASC').each do |filter|
      translate_filter(filter, filter.hub_feed)
      filter.destroy
    end

    HubFeedItemTagFilter.unscoped.order('updated_at ASC').each do |filter|
      translate_filter(filter, filter.feed_item)
      filter.destroy
    end

    # Delete any taggings that are duplicates in favor of owned taggings. Do
    # not remove any owned taggings.
    current_db.execute("DELETE FROM taggings WHERE id IN (SELECT t2.id FROM
                       taggings AS t1 JOIN taggings AS t2 ON t1.taggable_id
                       = t2.taggable_id AND t1.tag_id = t2.tag_id AND
                       t1.context = t2.context AND t1.id != t2.id WHERE
                       t1.tagger_id IS NOT NULL AND t2.tagger_id IS NULL);")
    
    # If multiple users own the same tagging, create the most recent as
    # a tagging and the remainder as deactivated taggings.
    to_deactivate = ActsAsTaggableOn::Tagging.find_by_sql(
      "SELECT * FROM (SELECT *, row_number() OVER w, first_value(id) OVER w FROM
      taggings WHERE tagger_id IS NOT NULL WINDOW w AS (PARTITION BY tag_id,
      taggable_id, context ORDER BY created_at DESC) ORDER BY first_value ASC,
      created_at DESC) AS ss WHERE row_number > 1;"
    )

    to_deactivate.each do |tagging|
      deactivator = ActsAsTaggableOn::Tagging.find(tagging.first_value)
      deactivator.deactivate_tagging(tagging)
    end

    bar = ProgressBar.new(ActsAsTaggableOn::Tagging.where('tagger_id IS NOT NULL').count)
    ActsAsTaggableOn::Tagging.where('tagger_id IS NOT NULL').each do |tagging|
      NewTagging.create(tagging.attributes)
      tagging.delete
      bar.increment!
    end

    # Locate all taggings that could have been applied by filters (in hub
    # contexts). Delete them as they can be recreated appropriately and
    # consistently.
    class AddTagFilter
      def potential_added_taggings
        ActsAsTaggableOn::Tagging.where(
          context: hub.tagging_key, tag_id: tag.id, taggable_type: FeedItem,
          taggable_id: items_in_scope.pluck(:id)
        ).where('tagger_id IS NULL')
      end
    end

    class ModifyTagFilter
      def potential_added_taggings
        item_ids_with_old_tag = NewTagging.where(
          taggable_id: items_in_scope.pluck(:id),
          tag_id: tag.id
        ).pluck(:id)
        ActsAsTaggableOn::Tagging.where(
          context: hub.tagging_key, tag_id: new_tag.id, taggable_type: FeedItem,
          taggable_id: item_ids_with_old_tag).where('tagger_id IS NULL')
      end
    end
    AddTagFilter.each do |filter|
      filter.potential_added_taggings.delete_all
    end
    ModifyTagFilter.each do |filter|
      filter.potential_added_taggings.delete_all
    end

    # Locate all owned taggings. These are from bookmarkers. Migrate them over
    # and delete the old.

    puts 'Turn indexing back on'
  end

  desc 'Parse out image URLs from all feed items'
  task :set_image_urls => :environment do |t|
    bar = ProgressBar.new(FeedItem.count)
    FeedItem.find_each do |fi|
      fi.method('set_image_url').call
      fi.save! if fi.changed?
      bar.increment!
    end
  end

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
    ExpireFileCache.new.perform
  end

  desc 'update feeds'
  task :update_feeds => :environment do
    UpdateFeeds.new.perform
  end
  
  desc 'Transmogrifies feed titles from email@example.com\'s bookmarks to username\'s bookmarks'
  task :cleanup_titles => :environment do
    Feed.where(:bookmarking_feed => true).each do |f|
      u = User.where(["roles.authorizable_id = ? and roles.authorizable_type = 'Feed' and roles.name ='creator'", f.id]).joins(:roles).first
      if u and f.title.include?(u.email)
        puts "feed #{f.id}: #{f.title} => '#{u.username}\'s boookmarks'"
        f.update_attribute(:title, "#{u.username}'s bookmarks")
      end
    end
  end
     
  desc 'clean up orphaned items'
  task :clean_orphan_items => :environment do
    original_sunspot_session = Sunspot.session
    Sunspot.session = Sunspot::Rails::StubSessionProxy.new(original_sunspot_session)
    
    conn = ActiveRecord::Base.connection

    results = conn.execute("select id from feeds where id not in(select feed_id from hub_feeds group by feed_id)")
    puts "Destroying Feeds #{results.collect{|r| r['id']}.join(',')}"
    Feed.destroy(results.collect{|r| r['id']})

    results = conn.execute('select id from feed_items except (select distinct feed_item_id from feed_items_feeds)')
    puts "Destroying #{results.count} FeedItems #{results.first(4).collect{|r| r['id']}.join(',')}"
    FeedItem.destroy(results.collect{|r| r['id']})

    Role.includes(:authorizable).where('authorizable_id is not null').all.each do|r|
      if r.authorizable.blank?
        puts "Destroying Role #{r.id}"
        Role.destroy(r.id)
      end
    end

    Sunspot.session = original_sunspot_session
  
  end

  desc 'tiny test hubs'
  task :tiny_test_hubs => :environment do
      u = User.new(:username => 'jdcc', :email => 'jclark@cyber.law.harvard.edu', :password => 'password', :password_confirmation => "password")
      u.save!
      u.confirm!

      planet_feeds = %w|
http://cyber.law.harvard.edu/news/feed
http://childrenshospitalblog.org/category/claire-mccarthy-md/feed/
http://www.shirky.com/weblog/feed/
http://reagle.org/joseph/blog/?flav=atom
http://www.matthewhindman.com/index.php/component/option,com_rss/feed,RSS2.0/no_html,1/
http://www.mediacloud.org/blog/feed/|

    add_example_feeds('Berkman Planet Test Hub', planet_feeds, 'jclark@cyber.law.harvard.edu')

  end

  desc 'test hubs'
  task :test_hubs => :environment do
    u = User.new(:username => 'jdcc', :email => 'jclark@cyber.law.harvard.edu', :password => 'password', :password_confirmation => "password")
    u.save
    u.confirm!

    u = User.new(:username => 'ps', :email => 'peter.suber@gmail.com', :password => 'testpass', :password_confirmation => "testpass")
    u.save
    u.confirm!

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

  add_example_feeds('Berkman Planet Test Hub', planet_feeds, 'jclark@cyber.law.harvard.edu')

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
