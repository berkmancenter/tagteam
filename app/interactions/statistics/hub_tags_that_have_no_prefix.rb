# frozen_string_literal: true

module Statistics
  class HubTagsThatHaveNoPrefix < ActiveInteraction::Base
    object :hub, class: Hub

    def execute
      return [] unless hub.settings[:official_tag_prefix]

      tags_not_prefixed = []

      hub.tags.each do |tag|
        split_tag = tag.name.split('.')

        tags_not_prefixed.push(tag) if split_tag.first != hub.settings[:official_tag_prefix]
      end

      tags_not_prefixed
    end
  end
end
