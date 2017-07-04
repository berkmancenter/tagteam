# frozen_string_literal: true

module Statistics
  class TagsUsedNotApproved < ActiveInteraction::Base
    object :hub, class: Hub
    integer :limit, default: nil

    def execute
      approved_tags = hub.hub_approved_tags.map(&:tag)

      not_approved = (hub.tags - ActsAsTaggableOn::Tag.where(name: approved_tags))
                     .sort_by { |tag| tag[:name] }

      return not_approved if not_approved.empty?
      return not_approved.take(limit) unless limit.nil?

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
            ta.id IN (' + not_approved.map(&:id).join(',') + ')
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
