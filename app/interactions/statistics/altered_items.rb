# frozen_string_literal: true

module Statistics
  class AlteredItems < ActiveInteraction::Base
    object :hub, class: Hub

    def execute
      {
        all: altered_all,
        modified: altered_by_modified,
        added: altered_by_added,
        deleted: altered_by_deleted,
        hub_wide: altered_by_hubwide
      }
    end

    def altered_all
      ActiveRecord::Base.connection.execute(
        '
        SELECT
          COUNT(*)
        FROM
          (
            SELECT
              tg.taggable_id
            FROM
              taggings AS tg
            JOIN
              feed_items AS fi ON tg.taggable_id = fi.id
            WHERE
              tg.context = \'' + hub.tagging_key.to_s + '\' AND
              tg.taggable_type = \'FeedItem\' AND
              tg.tagger_type != \'Feed\' AND
              EXTRACT(EPOCH FROM (tg.created_at - fi.created_at)) > 60
            UNION
            SELECT
              tg.taggable_id
            FROM
              deactivated_taggings AS tg
            JOIN
              feed_items AS fi ON tg.taggable_id = fi.id
            WHERE
              tg.context = \'' + hub.tagging_key.to_s + '\' AND
              tg.taggable_type = \'FeedItem\' AND
              tg.tagger_type != \'Feed\' AND
              EXTRACT(EPOCH FROM (tg.created_at - fi.created_at)) > 60
          ) AS subquery
          '
      ).first['count']
    end

    def altered_by_added
      ActiveRecord::Base.connection.execute(
        'SELECT
          COUNT(DISTINCT tg.taggable_id)
        FROM
          taggings AS tg
        JOIN
          feed_items AS fi ON tg.taggable_id = fi.id
        JOIN
          tag_filters AS tf ON tg.tagger_id = tf.id
        WHERE
          tg.context = \'' + hub.tagging_key.to_s + '\' AND
          tg.taggable_type = \'FeedItem\' AND
          ((tf.type = \'AddTagFilter\' AND tg.tagger_type = \'TagFilter\') OR tg.tagger_type = \'User\') AND
          EXTRACT(EPOCH FROM (tg.created_at - fi.created_at)) > 60'
      ).first['count']
    end

    def altered_by_deleted
      ActiveRecord::Base.connection.execute(
        'SELECT
          COUNT(DISTINCT tg.taggable_id)
        FROM
          deactivated_taggings AS tg
        JOIN
          feed_items AS fi ON tg.taggable_id = fi.id
        JOIN
          tag_filters AS tf ON tg.deactivator_id = tf.id
        WHERE
          tg.context = \'' + hub.tagging_key.to_s + '\' AND
          tg.taggable_type = \'FeedItem\' AND
          ((tf.type = \'DeleteTagFilter\') OR tg.deactivator_type = \'ActsAsTaggableOn::Tagging\')'
      ).first['count']
    end

    def altered_by_modified
      ActiveRecord::Base.connection.execute(
        'SELECT
          COUNT(DISTINCT tg.taggable_id)
        FROM
          deactivated_taggings AS tg
        JOIN
          feed_items AS fi ON tg.taggable_id = fi.id
        JOIN
          tag_filters AS tf ON tg.deactivator_id = tf.id
        WHERE
          tg.context = \'' + hub.tagging_key.to_s + '\' AND
          tg.taggable_type = \'FeedItem\' AND
          tf.type = \'ModifyTagFilter\''
      ).first['count']
    end

    def altered_by_hubwide
      ActiveRecord::Base.connection.execute(
        '
        SELECT
          COUNT(*)
        FROM
          (
            SELECT
              tg.taggable_id
            FROM
              taggings AS tg
            JOIN
              feed_items AS fi ON tg.taggable_id = fi.id
            JOIN
              tag_filters AS tf ON tg.tagger_id = tf.id
            WHERE
              tg.context = \'' + hub.tagging_key.to_s + '\' AND
              tg.taggable_type = \'FeedItem\' AND
              tg.tagger_type = \'TagFilter\' AND
              tf.scope_type = \'Hub\' AND
              EXTRACT(EPOCH FROM (tg.created_at - fi.created_at)) > 10
            UNION
            SELECT
              tg.taggable_id
            FROM
              deactivated_taggings AS tg
            JOIN
              feed_items AS fi ON tg.taggable_id = fi.id
            JOIN
              tag_filters AS tf ON tg.deactivator_id = tf.id
            WHERE
              tg.context = \'' + hub.tagging_key.to_s + '\' AND
              tg.taggable_type = \'FeedItem\' AND
              tg.deactivator_type = \'TagFilter\' AND
              tf.scope_type = \'Hub\' AND
              EXTRACT(EPOCH FROM (tg.created_at - fi.created_at)) > 10
          ) AS subquery
        '
      ).first['count']
    end
  end
end
