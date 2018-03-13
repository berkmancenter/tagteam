# frozen_string_literal: true

module FeedItems
  # Used during the Feed#update_feed spidering process to de-duplicate and
  # create a FeedItem if it doesn't exist. Tags from all sources are merged
  # into a FeedItem. Changes are tracked and saved on the FeedRetrieval object
  # passed into this method. If there are changes, a Resque job is created to
  # re-calculate tag facets.
  class CreateOrUpdate < ActiveInteraction::Base
    object :feed
    object :feed_retrieval
    object :item, class: Object # one of the FeedAbstract::Item::XX classes

    def execute
      fi = FeedItem.find_or_initialize_by(url: item.link)
      item_changelog = {}

      fi = parse_raw_item(feed_item: fi, raw_item: item)

      if fi.new_record?
        # logger.warn('dirty because there is a new feed_item')
        item_changelog[:new_record] = true
        feed.dirty = true
      end

      fi.feed_retrievals << feed_retrieval
      fi.feeds << feed unless fi.feeds.include?(feed)

      new_tags = []

      item.categories.map do |category|
        new_tags << category.match(/\s/).present? ? category.split(' ') : category
      end

      # Merge tags...
      new_tags = new_tags.flatten

      new_tags.flatten.map do |tag|
        ActsAsTaggableOn::Tag.normalize_name(tag)
      end

      new_tags.sort_by!(&:to_s)
      new_tags.uniq!(&:to_s)

      tag_context = Rails.application.config.global_tag_context
      old_tags = fi.all_tags_list_on(tag_context).dup.sort

      if new_tags != old_tags
        fi.add_tags(new_tags, tag_context, feed)

        # logger.warn('dirty because tags have changed')
        feed.dirty = true

        unless fi.new_record?
          # Be sure to update the feed changelog here in case
          # an item only has tag changes.
          item_changelog[:tags] = [old_tags, fi.all_tags_list_on(tag_context)]
          feed.changelog[fi.id] = item_changelog
        end
      end

      if fi.valid?
        if feed.changelog.keys.include?(fi.id) || fi.new_record?
          # This runs here because we're auto stripping and auto-truncating
          # columns and want the change tracking to be relative to these fixed
          # values.
          # logger.warn('dirty because a feed item changed or was created.')
          # logger.warn('dirty Changes: ' + fi.changes.inspect)
          item_changelog.merge!(fi.changes) unless fi.new_record?
          # logger.warn('dirty item_changelog: ' + item_changelog.inspect)
          feed.dirty = true
          fi.save
          feed.changelog[fi.id] = item_changelog
        end
      end

      fi
    end

    private

    def parse_raw_item(feed_item:, raw_item:)
      attrs = {
        title: raw_item.title,
        description: raw_item.summary
      }

      attrs.merge!(new_item_attributes(raw_item)) if feed_item.new_record?

      feed_item.assign_attributes(attrs)

      feed_item
    end

    def new_item_attributes(raw_item)
      attrs = {}

      attrs.merge!(
        authors: raw_item.author,
        content: raw_item.content,
        contributors: raw_item.contributor,
        guid: raw_item.guid,
        rights: raw_item.rights
      )

      attrs.merge!(new_item_dates(raw_item))

      attrs
    end

    def new_item_dates(raw_item)
      attrs = {}

      if raw_item.published.present? && raw_item.published.year >= 1900
        attrs[:date_published] = raw_item.published.to_datetime
      end

      if raw_item.updated.present? && raw_item.updated.year >= 1900
        attrs[:last_updated] = raw_item.updated.to_datetime
      end

      attrs
    end
  end
end
