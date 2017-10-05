# frozen_string_literal: true

module Statistics
  class TagsApproved < ActiveInteraction::Base
    object :hub, class: Hub
    integer :limit, default: nil

    def execute
      approved_tags = ActsAsTaggableOn::Tag.where(
        name: hub.hub_approved_tags.map(&:tag)
      )

      counts = ActsAsTaggableOn::Tag.find_by_sql(
        [
          'SELECT
            ta.*, count(*)
          FROM
            tags ta
          JOIN
            taggings AS tg ON tg.tag_id = ta.id
          WHERE
            tg.context = ? AND
            tg.taggable_type = ? AND
            ta.id IN (' + approved_tags.map(&:id).join(',') + ')
          GROUP BY
            ta.id
          ORDER BY count(*) DESC',
          hub.tagging_key, 'FeedItem'
        ]
      )

      tag_sorter = TagSorter.new(tags: counts, sort_by: :frequency)

      tag_sorter.sort
    end
  end
end
