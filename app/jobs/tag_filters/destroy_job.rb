# frozen_string_literal: true

module TagFilters
  class DestroyJob < ApplicationJob
    queue_as :default

    def perform(tag_filter, updater)
      tag_filter.queue_destroy_notification(updater)
      tag_filter.rollback
      tag_filter.destroy
    end
  end
end
