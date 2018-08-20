# frozen_string_literal: true
require 'rake_helper'
include RakeHelper
require 'auth_utilities'
namespace :tagteam do
  namespace :migrate do
    desc 'Migrate tag filters over to new system'
    task tag_filters: :environment do |_t|
      module MockTagFilter
        include AuthUtilities
        def filter
          filter_type.constantize.find_by_sql(
            "SELECT * FROM #{filter_type.tableize} WHERE id = #{filter_id}"
          ).first
        end
      end
      class HubTagFilter < ApplicationRecord
        belongs_to :hub, optional: true
        acts_as_authorization_object
        include MockTagFilter
      end
      class HubFeedTagFilter < ApplicationRecord
        belongs_to :hub_feed, optional: true
        has_one :hub, through: :hub_feed
        acts_as_authorization_object
        include MockTagFilter
      end
      class HubFeedItemTagFilter < ApplicationRecord
        belongs_to :hub, optional: true
        belongs_to :feed_item, optional: true
        acts_as_authorization_object
        include MockTagFilter
      end
      puts 'Migrating filters'
      ## Now do the hub taggings
      # Migrate all filters over.
      def translate_filter(filter, scope)
        if filter.filter.tag.name.include? ','
          tags = filter.filter.tag.name.split(',').map(&:strip)
          # puts "Split #{filter.filter.tag.name} into #{tags}"
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
          # puts "Old filter: #{filter.inspect}"
          # puts "Scope: #{scope.inspect}"
          # puts "New filter: #{new_filter.inspect}"
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
              filter.updated_at = Time.now
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
              filter.updated_at = Time.now
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
              filter.updated_at = Time.now
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
    task taggings: :environment do |_t|
      module MockTagFilter
        include AuthUtilities
        def filter
          filter_type.constantize.find_by_sql(
            "SELECT * FROM #{filter_type.tableize} WHERE id = #{filter_id}"
          ).first
        end
      end
      class HubTagFilter < ApplicationRecord
        belongs_to :hub, optional: true
        acts_as_authorization_object
        include MockTagFilter
      end
      class HubFeedTagFilter < ApplicationRecord
        belongs_to :hub, optional: true
        belongs_to :hub_feed, optional: true
        acts_as_authorization_object
        include MockTagFilter
      end
      class HubFeedItemTagFilter < ApplicationRecord
        belongs_to :hub, optional: true
        belongs_to :feed_item, optional: true
        acts_as_authorization_object
        include MockTagFilter
      end
      puts 'Make sure sunspot is disabled, or this will be really slow.'

      puts 'Destroying Hub 31'
      Hub.find(31).destroy unless Hub.where(id: 31).empty?
      Rake::Task['tagteam:clean_orphan_items'].invoke # Took about 2 hours 45 mins

      class NewTagging < ApplicationRecord
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
      puts 'CHECK ON THIS - Deleting bookmarker taggings from global context'
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
      puts 'Adding tagging owners to global tags'
      current_db.execute(
        "UPDATE taggings SET tagger_id = feed_items_feeds.feed_id, tagger_type
        = 'Feed' FROM feed_items_feeds WHERE feed_items_feeds.feed_item_id
        = taggings.taggable_id AND taggings.context = 'tags' AND
        taggings.tagger_id IS NULL;"
      )

      # Migrate over all the remaining taggings in the global context.
      unless ActsAsTaggableOn::Tagging.where(context: 'tags').empty?
        puts 'Migrating global taggings over to new prod'
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
            taggable_id: item_ids_with_old_tag
          ).where('tagger_id IS NULL')
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
      puts 'Assigning owners to bookmarker taggings and migrating'
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
        next unless tagger
        tagging.tagger = tagger
        NewTagging.create(tagging.attributes)
        tagging.delete
      end

      puts "Remaining taggings: #{ActsAsTaggableOn::Tagging.count}\n\n"

      # Delete taggings JSD created
      puts 'Deleting test taggings'
      ActsAsTaggableOn::Tagging.delete([3_095_895, 3_095_896, 3_360_595, 3_360_597])

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
        current_db.execute('DROP TABLE taggings')
      end

      puts 'Run: pg_dump -U tagteamdev -t taggings tagteam_prod_new | psql -U tagteamdev -d tagteam_prod'
      puts %q?Then run: echo "SELECT setval('taggings_id_seq', (SELECT MAX(id) FROM taggings));" | psql -U tagteamdev tagteam_prod?
      puts %q?Then run: echo "SELECT setval('deactivated_taggings_id_seq', (SELECT MAX(id) FROM deactivated_taggings));" | psql -U tagteamdev tagteam_prod?
      puts 'Then run: rake tagteam:migrate:copy_global_taggings'
    end

    desc 'Setup new taggings table'
    task copy_global_taggings: :environment do |_t|
      # Copy global taggings back into hub contexts.
      puts 'Copying global taggings into hub contexts'
      count = ActsAsTaggableOn::Tagging.where(context: 'tags').count
      bar = ProgressBar.new(count)
      ActsAsTaggableOn::Tagging.where(context: 'tags').find_each do |tagging|
        tagging.taggable.hubs.each do |hub|
          new_tagging = tagging.dup
          new_tagging.context = hub.tagging_key
          new_tagging.save! if new_tagging.valid?
        end
        bar.increment!
      end

      puts 'Run: rake tagteam:migrate:reapply_tag_filters'
    end

    desc 'Reapply all filters'
    task reapply_tag_filters: :environment do |_t|
      # TODO: Rerun tag filters
      bar = ProgressBar.new(TagFilter.count)
      Hub.all.each do |hub|
        hub.hub_feeds.each do |hub_feed|
          hub_feed.feed_items.find_each do |item|
            item.tag_filters.each { |f| f.apply; bar.increment! }
          end
          hub_feed.tag_filters.each { |f| f.apply; bar.increment! }
        end
        hub.tag_filters.each { |f| f.apply; bar.increment! }
      end

      puts 'Turn indexing back on and reindex'
    end
  end
end
