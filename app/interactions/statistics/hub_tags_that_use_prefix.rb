# frozen_string_literal: true

module Statistics
  class HubTagsThatUsePrefix < ActiveInteraction::Base
    object :hub, class: Hub

    def execute
      return [] unless hub.settings[:official_tag_prefix]

      tags_prefixed = []

      hub.tags.each do |tag|
        split_tag = tag.name.split('.')

        next if split_tag.length < 2

        tags_prefixed.push(tag) if split_tag.first == hub.settings[:official_tag_prefix]
      end

      tags_prefixed
    end
  end
end
