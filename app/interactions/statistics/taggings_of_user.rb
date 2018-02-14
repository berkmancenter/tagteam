# frozen_string_literal: true

module Statistics
  class TaggingsOfUser < ActiveInteraction::Base
    object :tag, class: ActsAsTaggableOn::Tag
    object :hub, class: Hub
    boolean :deprecated, default: false
    object :user, class: User

    def execute
      if deprecated
        table = 'deactivated_taggings'
      else
        table = 'taggings'
      end

      ActiveRecord::Base.connection.execute(
        'SELECT
          *
        FROM
          ' + table + ' AS tg
        WHERE
          tg.context = \'' + hub.tagging_key.to_s + '\' AND
          tg.taggable_type = \'FeedItem\' AND
          tg.tag_id = ' + tag.id.to_s + ' AND
          tg.tagger_id = ' + user.id.to_s + ' AND
          tg.tagger_type = \'User\'
        '
      )
    end
  end
end
