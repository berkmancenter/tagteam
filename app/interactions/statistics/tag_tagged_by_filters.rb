# frozen_string_literal: true

module Statistics
  class TagTaggedByFilters < ActiveInteraction::Base
    object :tag, class: ActsAsTaggableOn::Tag
    object :hub, class: Hub

    def execute
      ActsAsTaggableOn::Tagging.find_by_sql(
        [
          'SELECT
             t.*
           FROM
             taggings AS t
           WHERE
             t.context = ? AND
             t.tagger_type = ? AND
             t.tag_id = ?',
          hub.tagging_key, 'TagFilter', tag.id
        ]
      )
    end
  end
end
