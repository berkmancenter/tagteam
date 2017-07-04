# frozen_string_literal: true

module Statistics
  class HubTaggers < ActiveInteraction::Base
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

        filters += 't.created_at > \''
        filters += from.strftime('%Y-%m-%d %H:%M:%S')
        filters += '\' AND t.created_at < \''
        filters += to.strftime('%Y-%m-%d %H:%M:%S') + '\''
      end

      count('taggings', filters) + count('deactivated_taggings', filters)
    end

    def count(table, filters)
      ActiveRecord::Base.connection.execute(
        'SELECT
          COUNT(DISTINCT(t.tagger_id))
        FROM
          ' + table + ' AS t
        WHERE
          t.context = \'' + hub.tagging_key.to_s + '\' AND
          t.taggable_type = \'FeedItem\' AND
          t.tagger_type = \'User\'
          ' + filters
      ).first['count']
    end
  end
end
