require 'rake_helper'
include RakeHelper
require 'auth_utilities'

namespace :tagteam do
  namespace :migrate do
    desc 'Migrate tag filters over to new system'
    task :tag_filters => :environment do |t|
      module MockTagFilter
        include AuthUtilities
        def filter
          filter_type.constantize.find_by_sql(
            "SELECT * FROM #{filter_type.tableize} WHERE id = #{filter_id}"
          ).first
        end
      end
      class HubTagFilter < ActiveRecord::Base
        belongs_to :hub
        acts_as_authorization_object
        include MockTagFilter
      end
      class HubFeedTagFilter < ActiveRecord::Base
        belongs_to :hub_feed
        has_one :hub, through: :hub_feed
        acts_as_authorization_object
        include MockTagFilter
      end
      class HubFeedItemTagFilter < ActiveRecord::Base
        belongs_to :hub
        belongs_to :feed_item
        acts_as_authorization_object
        include MockTagFilter
      end
      puts 'Migrating filters'
      ## Now do the hub taggings
      # Migrate all filters over.
      def translate_filter(filter, scope)
        if filter.filter.tag.name.include? ','
          tags = filter.filter.tag.name.split(',').map(&:strip)
          #puts "Split #{filter.filter.tag.name} into #{tags}"
          tags.each do |tag|
            next if tag.empty?
            puts filter.inspect unless filter.filter_type == 'AddTagFilter'
            next unless filter.filter_type == 'AddTagFilter'
            new_tag = ActsAsTaggableOn::Tag.find_or_create_by_name_normalized(tag)
            new_filter = TagFilter.create
            attrs = {
              hub: filter.hub,
              scope: scope,
              tag: new_tag,
              type: filter.filter_type,
              applied: false,
              created_at: filter.created_at,
              updated_at: filter.updated_at
            }
            attrs.each do |attr, value|
              new_filter.send "#{attr}=", value
            end

            filter.owners.each do |owner|
              owner.has_role! :owner, new_filter
            end
            filter.creators.each do |creator|
              creator.has_role! :creator, new_filter
            end
            new_filter.save! if new_filter.valid? # Because we can end up
            # with duplicates now that we're splitting
          end
        else
          new_filter = TagFilter.create
          attrs = {
            hub: filter.hub,
            scope: scope,
            tag: filter.filter.tag,
            new_tag: filter.filter.new_tag,
            type: filter.filter_type,
            applied: false,
            created_at: filter.created_at,
            updated_at: filter.updated_at
          }
          attrs.each do |attr, value|
            new_filter.send "#{attr}=", value
          end

          filter.owners.each do |owner|
            owner.has_role! :owner, new_filter
          end
          filter.creators.each do |creator|
            creator.has_role! :creator, new_filter
          end
          #puts "Old filter: #{filter.inspect}"
          #puts "Scope: #{scope.inspect}"
          #puts "New filter: #{new_filter.inspect}"
          new_filter.save! if new_filter.valid?
        end
      end

      messages = []
      filter_count = HubTagFilter.unscoped.count +
        HubFeedTagFilter.unscoped.count +
        HubFeedItemTagFilter.unscoped.count
      unless filter_count == 0
        bar = ProgressBar.new(filter_count)
        HubTagFilter.unscoped.order('updated_at ASC').each do |filter|
          HubTagFilter.transaction do
            if filter.hub
              translate_filter(filter, filter.hub)
            else
              messages << "Could not find hub #{filter.hub_id}"
            end
            filter.destroy
          end
          bar.increment!
        end

        HubFeedTagFilter.unscoped.order('updated_at ASC').each do |filter|
          HubTagFilter.transaction do
            if filter.hub_feed && filter.hub
              translate_filter(filter, filter.hub_feed)
            elsif !filter.hub_feed
              messages << "Could not find hub feed #{filter.hub_feed_id}"
            else
              messages << "Could not find hub #{filter.hub_feed.hub_id}"
              # puts "Filter: #{filter.inspect}"
              # puts "Filter.filter: #{filter.filter.inspect}"
            end
            filter.destroy
          end
          bar.increment!
        end

        HubFeedItemTagFilter.unscoped.order('updated_at ASC').each do |filter|
          HubTagFilter.transaction do
            if filter.feed_item && filter.hub
              translate_filter(filter, filter.feed_item)
            elsif !filter.feed_item
              messages << "Could not find item #{filter.feed_item_id}"
            else
              messages << "Could not find hub #{filter.hub_id}"
            end
            filter.destroy
          end
          bar.increment!
        end

        puts messages.uniq.join("\n")
        puts "Turned #{filter_count} old filters into #{TagFilter.count} new filters"
      end
    end

    desc 'Migrate to new tag system'
    task :taggings => :environment do |t|
      module MockTagFilter
        include AuthUtilities
        def filter
          filter_type.constantize.find_by_sql(
            "SELECT * FROM #{filter_type.tableize} WHERE id = #{filter_id}"
          ).first
        end
      end
      class HubTagFilter < ActiveRecord::Base
        belongs_to :hub
        acts_as_authorization_object
        include MockTagFilter
      end
      class HubFeedTagFilter < ActiveRecord::Base
        belongs_to :hub
        belongs_to :hub_feed
        acts_as_authorization_object
        include MockTagFilter
      end
      class HubFeedItemTagFilter < ActiveRecord::Base
        belongs_to :hub
        belongs_to :feed_item
        acts_as_authorization_object
        include MockTagFilter
      end
      puts 'Make sure sunspot is disabled, or this will be really slow.'

      puts 'Destroying Hub 31'
      Hub.find(31).destroy unless Hub.where(id: 31).empty?
      Rake::Task['tagteam:clean_orphan_items'].invoke # Took about 2 hours 45 mins

      class NewTagging < ActiveRecord::Base
        establish_connection :new_production
        self.table_name = 'taggings'
        attr_accessible :id, :taggable_id, :taggable_type, :tag_id, :tagger_id,
          :tagger_type, :context, :created_at
      end

      current_db = ActiveRecord::Base.connection

      puts "Remaining taggings: #{ActsAsTaggableOn::Tagging.count}\n\n"
      ## Do the global taggings first
      # Delete the taggings from the global context that have a matching tagging
      # in the hub context with an owner. Those are from bookmarkers.
      puts "CHECK ON THIS - Deleting bookmarker taggings from global context"
      current_db.execute(
        "DELETE FROM taggings WHERE id IN (SELECT id FROM (SELECT *, count(*)
        OVER w, bool_or(context != 'tags' AND tagger_id IS NOT NULL) OVER
        w FROM taggings WINDOW w AS (PARTITION BY taggable_id, tag_id)) AS sq
        WHERE count > 1 AND bool_or IS true AND context = 'tags' AND
        tagger_type IS NULL);"
      )

      puts "Remaining taggings: #{ActsAsTaggableOn::Tagging.count}\n\n"

      # Delete any hub taggings that are duplicates of taggings in the global
      # context and don't have an owner. These are from feeds.
      puts 'Deleting feed taggings in hubs'
      current_db.execute(
        "DELETE FROM taggings WHERE id IN (SELECT sq.id FROM (SELECT
        taggings.*, count(*) OVER (PARTITION BY taggable_id, tag_id) FROM
        taggings WHERE tagger_id IS NULL) AS sq WHERE count > 1 AND context !=
          'tags')"
      )

      puts "Remaining taggings: #{ActsAsTaggableOn::Tagging.count}\n\n"

      # Find an owner for all remaining global taggings - really just the first
      # feed.  This will set a feed in some undetermined way, which is fine.
      puts "Adding tagging owners to global tags"
      current_db.execute(
        "UPDATE taggings SET tagger_id = feed_items_feeds.feed_id, tagger_type
        = 'Feed' FROM feed_items_feeds WHERE feed_items_feeds.feed_item_id
        = taggings.taggable_id AND taggings.context = 'tags' AND
        taggings.tagger_id IS NULL;"
      )


      # Migrate over all the remaining taggings in the global context.
      unless ActsAsTaggableOn::Tagging.where(context: 'tags').empty?
        puts "Migrating global taggings over to new prod"
        NewTagging.delete_all
        bar = ProgressBar.new(ActsAsTaggableOn::Tagging.where(context: 'tags').count)
        ActsAsTaggableOn::Tagging.where(context: 'tags').each do |tagging|
          NewTagging.create(tagging.attributes)
          tagging.delete
          bar.increment!
        end

        puts "Remaining taggings: #{ActsAsTaggableOn::Tagging.count}\n\n"
      end

      ######## Now do hub taggings

      puts 'Deleting unowned hub taggings with owned duplicates'
      # Delete any taggings that are duplicates in favor of owned taggings. Do
      # not remove any owned taggings.
      current_db.execute(
        "DELETE FROM taggings WHERE id IN (SELECT id FROM (SELECT taggings.*,
        count(*) OVER w, bool_or(tagger_id IS NOT NULL) OVER w FROM taggings
        WINDOW w AS (PARTITION BY taggable_id, tag_id, context)) AS sq WHERE
        count > 1 AND tagger_id IS NULL AND bool_or IS true);"
      )

      puts "Remaining taggings: #{ActsAsTaggableOn::Tagging.count}\n\n"

      puts 'Deactivating duplicate taggings'
      # If multiple users own the same tagging, create the most recent as
      # a tagging and the remainder as deactivated taggings.
      to_deactivate = ActsAsTaggableOn::Tagging.find_by_sql(
        "SELECT * FROM (SELECT *, row_number() OVER w, first_value(id) OVER w FROM
        taggings WHERE tagger_id IS NOT NULL WINDOW w AS (PARTITION BY tag_id,
        taggable_id, context ORDER BY created_at DESC) ORDER BY first_value ASC,
        created_at DESC) AS ss WHERE row_number > 1;"
      )
      count = to_deactivate.count
      unless count == 0
        bar = ProgressBar.new(count)
        to_deactivate.each do |tagging|
          deactivator = ActsAsTaggableOn::Tagging.find(tagging.first_value)

          attrs = tagging.attributes.except('row_number', 'first_value')
          tagging.instance_variable_set(:@attributes, attrs)

          deactivator.deactivate_tagging(tagging)
          bar.increment!
        end
      end

      puts "Remaining taggings: #{ActsAsTaggableOn::Tagging.count}\n\n"

      # Migrate over all the remaining taggings owned by someone or something.
      puts 'Migrating remaining owned taggings'
      count = ActsAsTaggableOn::Tagging.where('tagger_id IS NOT NULL').count
      unless count == 0
        bar = ProgressBar.new(count)
        ActsAsTaggableOn::Tagging.where('tagger_id IS NOT NULL').each do |tagging|
          NewTagging.create(tagging.attributes)
          tagging.delete
          bar.increment!
        end
      end

      puts "Remaining taggings: #{ActsAsTaggableOn::Tagging.count}\n\n"

      Rake::Task['tagteam:migrate:tag_filters'].invoke
      # Locate all taggings that could have been applied by filters (in hub
      # contexts). Delete them as they can be recreated appropriately and
      # consistently.
      AddTagFilter.class_eval do
        def potential_added_taggings
          ActsAsTaggableOn::Tagging.where(
            context: hub.tagging_key, tag_id: tag.id, taggable_type: FeedItem,
            taggable_id: items_in_scope.pluck(:id)
          ).where('tagger_id IS NULL')
        end
      end

      ModifyTagFilter.class_eval do
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
      count = AddTagFilter.count + ModifyTagFilter.count
      unless count == 0
        puts 'Removing taggings caused by filters'
        bar = ProgressBar.new(count)
        AddTagFilter.all.each do |filter|
          filter.potential_added_taggings.delete_all
          bar.increment!
        end
        ModifyTagFilter.all.each do |filter|
          filter.potential_added_taggings.delete_all
          bar.increment!
        end
        puts "Remaining taggings: #{ActsAsTaggableOn::Tagging.count}\n\n"
      end

      # Find any remaining taggings that are attached to a feed item which came
      # in through a hub feed that's a bookmark collection. Mark the tagging
      # owner as the user who is the owner of the bookmark collection.
      puts "Assigning owners to bookmarker taggings and migrating"
      taggings = ActsAsTaggableOn::Tagging.find_by_sql(
        "SELECT DISTINCT taggings.* FROM taggings JOIN feed_items ON
        taggable_id = feed_items.id JOIN feed_items_feeds ON
        feed_items_feeds.feed_item_id = feed_items.id JOIN feeds ON
        feed_items_feeds.feed_id = feeds.id WHERE feeds.bookmarking_feed IS
        true;"
      )
      count = taggings.count
      unless count == 0
        bar = ProgressBar.new(count)
        taggings.each do |tagging|
          tagging.tagger = tagging.taggable.feeds.where(bookmarking_feed: true).first.owners.first
          NewTagging.create(tagging.attributes)
          tagging.delete
          bar.increment!
        end
      end

      puts "Remaining taggings: #{ActsAsTaggableOn::Tagging.count}\n\n"

      # For any taggings that could have come from a filter, assume they did
      # even though we don't have an old tagging in the DB. Migrate.
      puts 'Giving remaining taggings to modify tag filter candidates'
      ActsAsTaggableOn::Tagging.all.each do |tagging|
        tagger = ModifyTagFilter.where(new_tag_id: tagging.tag_id, hub_id:
                              tagging.context.sub('hub_', '')).last
        if tagger
          tagging.tagger = tagger
          NewTagging.create(tagging.attributes)
          tagging.delete
        end
      end

      puts "Remaining taggings: #{ActsAsTaggableOn::Tagging.count}\n\n"

      # Delete taggings JSD created
      puts 'Deleting test taggings'
      ActsAsTaggableOn::Tagging.delete([3095895, 3095896, 3360595, 3360597])

      puts "Remaining taggings: #{ActsAsTaggableOn::Tagging.count}\n\n"
      
      puts 'Giving any remaining taggings to their feeds'
      ActsAsTaggableOn::Tagging.all.each do |tagging|
        tagger = tagging.taggable.feeds.first
        tagging.tagger = tagger
        NewTagging.create(tagging.attributes)
        tagging.delete
      end

      puts "Remaining taggings: #{ActsAsTaggableOn::Tagging.count}\n\n"

      if ActsAsTaggableOn::Tagging.count == 0
        puts 'Dropping taggings table'
        current_db.execute("DROP TABLE taggings")
      end

      puts "Run: pg_dump -U tagteamdev -t taggings tagteam_prod_new | psql -U tagteamdev -d tagteam_prod"
      puts %q?Then run: echo "SELECT setval('taggings_id_seq', (SELECT MAX(id) FROM taggings));" | psql -U tagteamdev tagteam_prod?
      puts "Then run: rake tagteam:migrate:setup_taggings"
    end

    desc 'Setup new taggings table'
    task :setup_taggings => :environment do |t|

      # Copy global taggings back into hub contexts.
      puts 'Copying global taggings into hub contexts'
      count = ActsAsTaggableOn::Tagging.where(context: 'tags').count
      bar = ProgressBar.new(count)
      ActsAsTaggableOn::Tagging.where(context: 'tags').each do |tagging|
        tagging.taggable.hubs.each do |hub|
          new_tagging = tagging.dup
          new_tagging.context = hub.tagging_key
          new_tagging.save! if new_tagging.valid?
        end
        bar.increment!
      end

      puts 'Reapply tag filters'
      puts 'Turn indexing back on and reindex'
    end

    desc 'Reapply all filters'
    task :reapply_tag_filters => :environment do |t|
      # TODO: Rerun tag filters
      bar = ProgressBar.new(TagFilter.count)
      Hub.all.each do |hub|
        hub.hub_feeds.each do |hub_feed|
          hub_feed.feed_items.find_each do |item|
            item.tag_filters.each{ |f| f.apply; bar.increment! }
          end
          hub_feed.tag_filters.each{ |f| f.apply; bar.increment! }
        end
        hub.tag_filters.each{ |f| f.apply; bar.increment! }
      end
    end
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
    results.each{ |r| FeedItem.destroy(r['id']) }

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
