require 'json'

module Tagteam
  class ExportImport
    # get and structure user hubs data
    def self.get_all_user_data(current_user)
      data_structure = {
        hubs: []
      }

      user_hubs = current_user.my(Hub)

      user_hubs.each do |hub|
        # process remixes
        remixes = []
        input_sources = []

        hub.republished_feeds.each do |remix|
          remix_to_add = {
            remix: remix
          }

          remixes << remix_to_add
          input_sources += remix.input_sources
        end

        # process users
        users = []
        hub.users_with_roles.each do |user|
          user_to_add = {
            user: user,
            roles: user.roles
          }

          users << user_to_add
        end

        # process feed items
        feed_items = []
        hub.feed_items.each do |feed_item|
          feed_item_to_add = {
            feed_item: feed_item,
            feeds: feed_item.feeds
          }

          feed_items << feed_item_to_add
        end

        # structure hub
        hub_to_add = {
          hub: hub,
          feeds: hub.feeds,
          filters: hub.all_tag_filters,
          remixes: remixes,
          input_sources: input_sources,
          feed_items: feed_items,
          tags: hub.tags,
          users: users
        }

        data_structure[:hubs] << hub_to_add.as_json
      end

      # convert to a nice and shiny JSON object
      JSON.pretty_generate(data_structure)
    end

    def self.import(content)
      data = JSON.parse(content, symbolize_names: true)

      if validate_data(data) && !data[:hubs].empty?
        return process_data_import(data)
      end

      false
    end

    def self.validate_data(data)
      return true if data.include?(:hubs)

      false
    end

    def self.process_data_import(data)
      data[:hubs].each do |hub_data|
        imported_hub = import_hub(hub_data[:hub])

        imported_feeds = import_feeds(hub_data[:feeds], imported_hub[:new_id])

        imported_tags = import_tags(hub_data[:tags])

        imported_feed_items = import_feed_items(
          hub_data[:feed_items],
          imported_feeds
        )

        imported_filters = import_filters(
          hub_data[:filters],
          imported_tags,
          imported_hub[:new_id],
          imported_feeds,
          imported_feed_items
        )

        imported_remixes = import_remixes(
          hub_data[:remixes],
          imported_hub[:new_id],
          imported_feeds,
          imported_feed_items,
          imported_tags
        )

        imported_input_sources = import_input_sources(
          hub_data[:input_sources],
          imported_hub[:new_id],
          imported_feeds,
          imported_feed_items,
          imported_tags,
          imported_remixes
        )

        imported_users = import_users(
          hub_data[:users],
          imported_hub[:new_id],
          imported_feeds,
          imported_tags,
          imported_feed_items,
          imported_filters,
          imported_remixes,
          imported_input_sources
        )

        Sidekiq::Client.enqueue(RecalcAllItems, imported_hub[:new_id])
      end

      Notifications.user_data_import_completion_notification(email, true)
    end

    def self.import_hub(hub)
      new_hub = Hub.new
      new_hub.attributes = hub.except(:id)

      new_hub.save!

      {
        old_id: hub[:id],
        new_id: new_hub.id
      }
    end

    def self.import_feeds(feeds, hub_id)
      new_feeds = []

      feeds.each do |feed|
        existing_feed = Feed.where(feed_url: feed[:feed_url]).first

        if existing_feed.nil?
          new_feed = Feed.new

          new_feed.attributes = feed.except(:id)

          new_feed.save!

          new_id = new_feed.id
        else
          new_id = existing_feed.id
        end

        new_feeds << {
          old_id: feed[:id],
          new_id: new_id
        }

        hub_feed = HubFeed.new
        hub_feed.feed_id = new_id
        hub_feed.hub_id = hub_id

        hub_feed.save!
      end

      new_feeds
    end

    def self.import_tags(tags)
      new_tags = []

      tags.each do |tag|
        existing_tag = ActsAsTaggableOn::Tag.where(name: tag[:name]).first

        if existing_tag.nil?
          new_tag = ActsAsTaggableOn::Tag.new

          new_tag.name = tag[:name]

          new_tag.save!

          new_tags << {
            old_id: tag[:id],
            new_id: new_tag.id
          }
        else
          new_tags << {
            old_id: tag[:id],
            new_id: existing_tag.id
          }
        end
      end

      new_tags
    end

    def self.import_filters(filters, tags, hub_id, feeds, items)
      new_filters = []

      filters.each do |filter|
        new_filter = TagFilter.new

        new_filter.attributes = filter.except(:id)

        if filter[:scope_type] == 'Hub'
          new_filter.scope_id = hub_id
        elsif filter[:scope_type] == 'HubFeed'
          new_filter.scope_id = feeds.select { |feed| feed[:old_id] == filter[:scope_id] }.first[:new_id]
        elsif filter[:scope_type] == 'FeedItem'
          new_filter.scope_id = items.select { |item| item[:old_id] == filter[:scope_id] }.first[:new_id]
        else
          next
        end

        new_filter.hub_id = hub_id
        new_filter.tag_id = tags.select { |tag| tag[:old_id] == filter[:tag_id] }.first[:new_id]

        new_filter.save!

        new_filters << {
          old_id: filter[:id],
          new_id: new_filter.id
        }
      end

      new_filters
    end

    def self.import_feed_items(items, feeds)
      new_items = []

      items.each do |item|
        existing_item = FeedItem.where(url: item[:feed_item][:url]).first

        if existing_item.nil?
          new_item = FeedItem.new

          new_item.attributes = item[:feed_item].except(:id)

          new_item.feeds = Feed.where(id: feeds_old_to_new(item[:feeds], feeds))

          new_item.save!

          new_id = new_item.id
        else
          existing_item.feeds = Feed.where(
            id: existing_item.feeds.pluck(:id) + feeds_old_to_new(item[:feeds], feeds)
          )

          existing_item.save!

          new_id = existing_item.id
        end

        new_items << {
          old_id: item[:feed_item][:id],
          new_id: new_id
        }
      end

      new_items
    end

    def self.feeds_old_to_new(feeds_old, all_feeds)
      mapped_feeds = []

      feeds_old.each do |feed_old|
        to_map = all_feeds.select { |feed| feed[:old_id] == feed_old[:id] }.first

        next if to_map.nil?

        mapped_feeds << to_map[:new_id]
      end

      mapped_feeds
    end

    def self.import_remixes(remixes, hub_id, feeds, feed_items, tags)
      new_remixes = []

      remixes.each do |remix_data|
        existing_remix = RepublishedFeed.where(url_key: remix_data[:remix][:url_key]).first

        new_remix = RepublishedFeed.new

        new_remix.attributes = remix_data[:remix].except(:id)

        unless existing_remix.nil?
          new_remix.url_key = remix_data[:remix][:url_key] + hub_id.to_s
        end

        new_remix.hub_id = hub_id

        new_remix.save!

        new_id = new_remix.id

        new_remixes << {
          old_id: remix_data[:remix][:id],
          new_id: new_id
        }
      end

      new_remixes
    end

    def self.import_input_sources(input_sources, hub_id, feeds, feed_items, tags, remixes)
      new_input_sources = []

      input_sources.each do |input_source|
        remix_id = remixes.select { |remix| remix[:old_id] == input_source[:republished_feed_id] }.first[:new_id]

        existing_input_source = InputSource.where(
          item_source_type: input_source[:item_source_type],
          item_source_id: input_source[:item_source_id],
          effect: input_source[:effect],
          republished_feed_id: remix_id
        ).first

        if existing_input_source.nil?
          new_input_source = InputSource.new

          if input_source[:item_source_type] == 'Feed'
            new_input_source.item_source_id = feeds.select { |feed| feed[:old_id] == input_source[:item_source_id] }.first[:new_id]
          elsif input_source[:item_source_type] == 'FeedItem'
            new_input_source.item_source_id = feed_items.select { |feed_item| feed_item[:old_id] == input_source[:item_source_id] }.first[:new_id]
          elsif input_source[:item_source_type] == 'ActsAsTaggableOn::Tag'
            new_input_source.item_source_id = tags.select { |tag| tag[:old_id] == input_source[:item_source_id] }.first[:new_id]
          else
            next
          end

          new_input_source.attributes = input_source.except(:id)

          new_input_source.republished_feed_id = remix_id

          new_input_source.save!

          new_input_sources << {
            old_id: input_source[:id],
            new_id: new_input_source.id
          }
        else
          new_input_sources << {
            old_id: input_source[:id],
            new_id: existing_input_source.id
          }
        end
      end

      new_input_sources
    end

    def self.import_users(users, hub_id, feeds, tags, feed_items, filters, remixes, input_sources)
      new_users = []

      users.each do |user|
        exisiting_user = User.where(email: user[:user][:email]).first

        if exisiting_user.nil?
          new_user = User.new

          new_user.attributes = user[:user].except(:id)

          new_user.save!
        else
          new_user = exisiting_user
        end

        user[:roles].each do |role|
          new_role = Role.new

          new_role.attributes = role.except(:id)
          new_role.authorizable_type = role[:authorizable_type]

          case role[:authorizable_type]
          when 'Hub'
            new_role.authorizable_id = hub_id
          when 'Feed'
            related_item = feeds.select { |feed| feed[:old_id] == role[:authorizable_id] }.first

            next if related_item.nil?

            new_role.authorizable_id = related_item[:new_id]
          when 'TagFilter'
            related_item = filters.select { |filter| filter[:old_id] == role[:authorizable_id] }.first

            next if related_item.nil?

            new_role.authorizable_id = related_item[:new_id]
          when 'RepublishedFeed'
            related_item = remixes.select { |remix| remix[:old_id] == role[:authorizable_id] }.first

            next if related_item.nil?

            new_role.authorizable_id = related_item[:new_id]
          when 'InputSource'
            related_item = input_sources.select { |input_source| input_source[:old_id] == role[:authorizable_id] }.first

            next if related_item.nil?

            new_role.authorizable_id = related_item[:new_id]
          else
            next
          end

          new_role.users = [new_user]

          new_role.save!
        end

        new_users << {
          old_id: user[:id],
          new_id: new_user.id
        }
      end
    end
  end
end
