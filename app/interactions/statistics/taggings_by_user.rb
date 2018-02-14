# frozen_string_literal: true

module Statistics
  class TaggingsByUser < ActiveInteraction::Base
    object :tag, class: ActsAsTaggableOn::Tag
    object :hub, class: Hub
    boolean :deprecated, default: false

    def execute
      table = if deprecated
                'deactivated_taggings'
              else
                'taggings'
              end

      ActiveRecord::Base.connection.execute(
        'SELECT
          COUNT(tg.id) AS count, tg.tagger_id
        FROM
          ' + table + ' AS tg
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
  end
end
