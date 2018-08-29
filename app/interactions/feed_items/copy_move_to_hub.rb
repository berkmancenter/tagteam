# frozen_string_literal: true

module FeedItems
  class CopyMoveToHub < ActiveInteraction::Base
    object :feed_item
    object :from_hub_feed, class: HubFeed
    object :to_hub, class: Hub
    object :current_user, class: User
    string :action_type

    def execute
      from_hub = from_hub_feed.hub

      feed_item.all_tags_on(from_hub.tagging_key).map do |tag|
        from_tagging = ActsAsTaggableOn::Tagging.find_by(
          tag: tag,
          taggable: feed_item,
          context: from_hub.tagging_key
        )

        new_tag_user = current_user
        if from_tagging.tagger_type == 'User'
          from_user = from_tagging.tagger
        elsif from_tagging.tagger_type == 'TagFilter'
          unless from_tagging.tagger.nil?
            from_user = from_tagging.tagger.users.first
          end
        end

        unless from_user.nil?
          if from_user.is?([:owner, :bookmarker, :hub_tag_adder, :hub_feed_tag_filterer]) ||
             from_user.superadmin?
            new_tag_user = from_user
          end
        end

        ActsAsTaggableOn::Tagging.create(
          tag: tag,
          taggable: feed_item,
          tagger: new_tag_user,
          context: to_hub.tagging_key
        )
      end

      if action_type == 'copy'
        feed_item.feeds << current_user.get_default_bookmarking_bookmark_collection_for(to_hub.id)
        feed_item.save!
      elsif action_type == 'move'
        feed_item.feeds -= [from_hub_feed.feed]
        feed_item.feeds << current_user.get_default_bookmarking_bookmark_collection_for(to_hub.id)
        feed_item.save!
      end

      TagFilter.apply_hub_filters(to_hub, feed_item)
      feed_item.reload.solr_index
    end
  end
end
