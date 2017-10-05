# frozen_string_literal: true

module Statistics
  class DeprecatedTags < ActiveInteraction::Base
    object :hub, class: Hub
    string :month, default: nil
    string :year, default: nil

    def execute
      filters = ''

      if year && year != 'false'
        filters += ' AND '

        if month && month != 'false'
          from = DateTime.new(year.to_i, Date::MONTHNAMES.index(month))
                         .at_beginning_of_month
          to = DateTime.new(year.to_i, Date::MONTHNAMES.index(month))
                       .at_end_of_month
        else
          from = DateTime.new(year.to_i, 1).at_beginning_of_month
          to = DateTime.new(year.to_i, 12).at_end_of_month
        end

        filters += 'tg.created_at > \''
        filters += from.strftime('%Y-%m-%d %H:%M:%S')
        filters += '\' AND tg.created_at < \''
        filters += to.strftime('%Y-%m-%d %H:%M:%S') + '\''
      end

      counts = ActsAsTaggableOn::Tag.find_by_sql(
        [
          'SELECT
            ta.*, count(*)
          FROM
            tags ta
          JOIN
            deactivated_taggings AS tg ON tg.tag_id = ta.id
          WHERE
            ta.id IN (' + hub.deprecated_tags.map(&:id).join(',') + ')
            ' + filters + '
          GROUP BY
            ta.id'
        ]
      )

      return [] if counts.empty?

      tag_sorter = TagSorter.new(tags: counts, sort_by: :frequency)

      tag_sorter.sort
    end
  end
end
