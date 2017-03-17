# frozen_string_literal: true
class DestroyTagFilter
  include Sidekiq::Worker

  def self.display_name
    'Destroying a tag filter'
  end

  def perform(filter_id, user_id)
    filter = TagFilter.find(filter_id)
    user = User.find(user_id)
    filter.rollback

    # send an email notification about an items update
    if filter.hub.allow_taggers_to_sign_up_for_notifications
      items_to_process = filter.items_to_modify.collect(&:id).join(',')

      filter.notify_about_items_modification(filter.hub, user, items_to_process)
    end

    filter.destroy
  end
end
