require 'rake_helper'
include RakeHelper
require 'auth_utilities'

namespace :tagteam do
  desc 'Parse out image URLs from all feed items'
  task :set_image_urls => :environment do |t|
    bar = ProgressBar.new(FeedItem.count)
    FeedItem.find_each do |fi|
      fi.method('set_image_url').call
      fi.save! if fi.changed?
      bar.increment!
    end
  end

  desc 'Remove taggings that should not exist'
  task :destroy_spurious_taggings => :environment do
    puts 'Destroying by SQL'
    # Destroy the easy ones first to save time.
    ActsAsTaggableOn::Tagging.find_by_sql("select taggings.* from taggings join
    tag_filters on taggings.tagger_id = tag_filters.id where
    taggings.tagger_type = 'TagFilter' and tag_filters.scope_type = 'FeedItem'
    and tag_filters.scope_id != taggings.taggable_id;").map(&:destroy)

    puts 'Destroying by ruby'
    bar = ProgressBar.new(ActsAsTaggableOn::Tagging.where(tagger_type: 'TagFilter').count)
    ActsAsTaggableOn::Tagging.where(tagger_type: 'TagFilter').find_each do |tagging|
      unless tagging.tagger.items_in_scope.pluck(:id).include? tagging.taggable_id
        tagging.destroy
      end
      bar.increment!
    end
  end

  desc 'Reapply all filters in a hib'
  task :reapply_filters, [:hub_id] => :environment do |t, args|
    RecalcAllItems.new.perform(args[:hub_id])
  end

  desc 'Make sure taggings are consistent with filters'
  task :audit_taggings => :environment do

    # Goal: Find taggings that are inconsistent with the current state of
    # filters. Do this by trimming down the number of taggings as far as
    # possible, and then looking through the remaining taggings for
    # inconsistencies.

    # Bring all tag filters into memory
    add_tag_filters = AddTagFilter.all
    mod_tag_filters = ModifyTagFilter.all
    del_tag_filters = DeleteTagFilter.all

    extra_taggings = []
    missing_taggings = []
    questionable_filters = []

    ###
    # First look for any taggings that should have been removed but weren't.
    # This is the easier case. Modify filters and delete filters remove tags

    # Find taggings with tags that some filters remove
    maybe_extra_taggings = ActsAsTaggableOn::Tagging.find_by_sql(
      "SELECT * FROM taggings WHERE tag_id IN
      (SELECT DISTINCT(tag_id) FROM tag_filters
      WHERE type IN ('ModifyTagFilter', 'DeleteTagFilter'));"
    )

    def relevant_filters(filters, tagging)
      filters.select{|f| f.tag_id == tagging.tag_id}
    end

    def tagging_in_scope?(filter, tagging)
      filter.scope.taggable_items.where(id: tagging.taggable_id).any?
    end

    # TODO: Am I ignoring context incorrectly here?
    bar = ProgressBar.new(maybe_extra_taggings.count)
    maybe_extra_taggings.each do |tagging|
      filters = relevant_filters(mod_tag_filters + del_tag_filters, tagging)
      filters.each do |filter|
        if tagging_in_scope?(filter, tagging)
          extra_taggings << { tagging: tagging.id, filter: filter.id }
          questionable_filters << filter.id
        end
      end
      bar.increment!
    end

    ###
    # Now look for the absence of taggings where they should exist. Add filters
    # and modify filters both add taggings

    bar = ProgressBar.new((add_tag_filters + mod_tag_filters).count)
    (add_tag_filters + mod_tag_filters).each do |filter|
      taggable_ids = filter.scope.taggable_items.pluck(:id)
      tag_id = filter.is_a?(ModifyTagFilter) ? filter.new_tag_id : filter.tag_id

      sql = 'SELECT id FROM
            (SELECT feed_items.id, bool_or(taggings.tag_id = ' + tag_id.to_s + ')
            AS has_tag FROM feed_items
            JOIN "taggings" ON "feed_items"."id" = "taggings"."taggable_id"
            WHERE feed_items.id IN (' + taggable_ids.join(', ') + ')
            GROUP BY feed_items.id) AS t1
            WHERE has_tag = false'
      items_missing_tag = FeedItem.find_by_sql(sql)
      items_missing_tag.each do |item|
        missing_taggings << { tag: tag_id, filter: filter.id, item: item.id }
        questionable_filters << filter.id
      end
      bar.increment!
    end

    puts "Possible extra tagging count: #{extra_taggings.count}"
    puts "Possible missing tagging count: #{missing_taggings.count}"
    puts "Questionable filters: #{questionable_filters.uniq}"
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
end
