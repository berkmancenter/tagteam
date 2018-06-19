# frozen_string_literal: true

module Statistics
  class TaggingsByUser < ActiveInteraction::Base
    object :tag, class: ActsAsTaggableOn::Tag
    object :hub, class: Hub
    boolean :deprecated, default: false
    boolean :after, default: false

    def execute
      if deprecated && after
        deprecated_after_taggings
      elsif deprecated
        deprecated_before_taggings
      else
        all_taggings
      end
    end

    def deprecated_before_taggings
      deprecated_taggings false
    end

    def deprecated_after_taggings
      deprecated_taggings true
    end

    def all_taggings
      ActiveRecord::Base.connection.execute(
        'SELECT
          COUNT(tg.id) AS count, tg.tagger_id
        FROM
          taggings AS tg
        WHERE
          tg.context = \'' + hub.tagging_key.to_s + '\' AND
          tg.taggable_type = \'FeedItem\' AND
          tg.tag_id = ' + tag.id.to_s + ' AND
          tg.tagger_type = \'User\'
        GROUP BY
          tg.tagger_id
        ORDER BY
          count DESC'
      )
    end

    def deprecated_taggings(after)
      deprecation_filter = hub
                           .all_tag_filters
                           .where(
                             scope_type: 'Hub',
                             tag_id: tag.id
                           )
                           .where.not(new_tag_id: nil)
                           .order('created_at ASC')
                           .limit(1)
                           .first

      return [] if deprecation_filter.nil?

      deprecation_date = deprecation_filter.created_at.utc.to_s
      if after
        deprecation_date_filter = 'tg.created_at > \'' + deprecation_date + '\''
      else
        deprecation_date_filter = 'tg.created_at < \'' + deprecation_date + '\''
      end

      ActiveRecord::Base.connection.execute(
        'SELECT
          COUNT(tg.id) AS count, tg.tagger_id
        FROM
          deactivated_taggings AS tg
        WHERE
          tg.context = \'' + hub.tagging_key.to_s + '\' AND
          tg.taggable_type = \'FeedItem\' AND
          tg.tag_id = ' + tag.id.to_s + ' AND
          tg.tagger_type = \'User\' AND
          tg.deactivator_type = \'TagFilter\' AND
          ' + deprecation_date_filter + '
        GROUP BY
          tg.tagger_id
        ORDER BY
          count DESC'
      )
    end
  end
end
