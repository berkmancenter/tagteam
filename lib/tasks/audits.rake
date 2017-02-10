# frozen_string_literal: true
require 'rake_helper'
include RakeHelper
require 'auth_utilities'

namespace :tagteam do
  namespace :audit do
    desc 'Make sure each tag filter is reflected in taggings'
    task :tag_filters, [:hub_id] => :environment do |_t, args|
      require 'rspec/rails'
      require Rails.root.join('spec/support/tag_utils.rb')

      tag_filters = TagFilter.order(:id)

      if args[:hub_id]
        hub = Hub.find(args[:hub_id])
        tag_filters = hub.all_tag_filters

        # Try to make this case faster by loading all tag lists into memory
        puts 'Building tag lists in memory'
        bar = ProgressBar.new(hub.feed_items.count)
        cached_tag_lists = hub.feed_items.map do |item|
          bar.increment!
          [item.id, item.all_tags_list_on(hub.tagging_key)]
        end
      end

      def cached_tag_lists_for(items, cached_tag_lists)
        item_ids = items.pluck(:id)
        if items.count == cached_tag_lists.count
          return cached_tag_lists.map(&:last)
        end
        cached_tag_lists.select { |list| item_ids.include?(list[0]) }.map(&:last)
      end

      group = RSpec.describe 'tagging consistency' do
        it 'shows the effects of every tag filter' do
          bar = ProgressBar.new(tag_filters.count)
          results = []
          tag_filters.each do |filter|
            begin
              tag_lists = if args[:hub_id]
                            cached_tag_lists_for(filter.items_in_scope, cached_tag_lists)
                          else
                            tag_lists_for(filter.items_in_scope, filter.hub.tagging_key)
                          end
              # TODO: Take into consideration filter chains (the first filters
              # will show up as false because their tags aren't showing
              # TODO: Take into consideration conflicting filters
              expect(tag_lists).to(show_effects_of(filter))
              results << { result: true, filter: filter.id }
              # puts "Tested #{filter.id} - #{filter.items_in_scope.count} items - #{results}"
              bar.increment!
            rescue Exception #=> e
              # puts e.inspect
              results << { result: false, filter: filter.id }
              # puts "Tested #{filter.id} - #{filter.items_in_scope.count} items - #{results}"
              bar.increment!
              next
            end
          end
          puts results.inspect
        end
      end

      puts 'Running tests'
      group.run
    end

    desc 'Make sure taggings are consistent with filters (~30 mins)'
    task :taggings, [:context] => :environment do |_t, args|
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
        WHERE type IN ('ModifyTagFilter', 'DeleteTagFilter'))
        #{args[:context] ? "AND context = '#{args[:context]}'" : ''};"
      )

      def tagging_hub(tagging)
        matches = tagging.context.match(/hub_(\d+)/)
        matches ? matches[1].to_i : nil
      end

      def relevant_filters(filters, tagging)
        filters.select do |f|
          hub = tagging_hub(tagging)
          matches = (f.tag_id == tagging.tag_id)
          hub ? matches && f.hub.id == hub : matches
        end
      end

      def tagging_in_scope?(filter, tagging)
        filter.scope.taggable_items.where(id: tagging.taggable_id).any?
      end

      # TODO: Am I ignoring context incorrectly here?
      puts 'Looking for spurious taggings'
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

      puts 'Looking for missing taggings'
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
  end
end
