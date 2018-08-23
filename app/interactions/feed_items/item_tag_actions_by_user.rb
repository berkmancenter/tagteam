# frozen_string_literal: true

module FeedItems
  class ItemTagActionsByUser < ActiveInteraction::Base
    object :feed_item
    object :hub

    def execute
      actions = {}

      @feed_item.taggings.where(context: hub.tagging_key).each do |tagging|
        begin
          if tagging[:tagger_type] == 'User'
            (actions[tagging.tagger.username] ||= []) << {
              tagger: tagging.tagger,
              tag: tagging.tag,
              type: 'added',
              date: tagging.created_at
            }
          end

          if tagging[:tagger_type] == 'TagFilter'
            filter_type = tagging.tagger.type
            tagger = tagging.tagger.users.first

            if filter_type == 'AddTagFilter'
              (actions[tagger.username] ||= []) << {
                tagger: tagger,
                tag: tagging.tag,
                type: 'added',
                date: tagging.created_at
              }
            end

            if filter_type == 'ModifyTagFilter'
              (actions[tagger.username] ||= []) << {
                tagger: tagger,
                tag: tagging.tagger.tag,
                new_tag: tagging.tagger.new_tag,
                type: 'modified',
                date: tagging.created_at
              }
            end
          end
        rescue
          # Removed user, tag filter
        end
      end

      deactivated_taggings = DeactivatedTagging.where(
        taggable_id: @feed_item.id,
        deactivator_type: 'TagFilter',
        context: hub.tagging_key
      )
      deactivated_taggings.each do |tagging|
        begin
          deactivator = TagFilter.find(tagging.deactivator_id)
          if tagging.tagger_type == 'TagFilter'
            activator = TagFilter.find(tagging.tagger_id).users.first
          elsif tagging.tagger_type == 'User'
            activator = User.find(tagging.tagger_id)
          end
          tag = ActsAsTaggableOn::Tag.find(tagging.tag_id)
          filter_type = deactivator.type

          if filter_type == 'DeleteTagFilter'
            (actions[deactivator.users.first.username] ||= []) << {
              tagger: deactivator.users.first,
              tag: tag,
              type: 'deleted',
              date: deactivator.created_at
            }

            (actions[activator.username] ||= []) << {
              tagger: activator,
              tag: tag,
              type: 'added',
              date: tagging.created_at
            }
          end

          if filter_type == 'ModifyTagFilter'
            (actions[activator.username] ||= []) << {
              tagger: activator,
              tag: tag,
              type: 'added',
              date: tagging.created_at
            }
          end
        rescue
          # Removed user, tag filter
        end
      end

      actions.each do |username, user_actions|
        user_actions.sort_by! { |k| k[:date] }
      end

      actions
    end
  end
end
