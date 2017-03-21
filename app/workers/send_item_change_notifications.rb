# frozen_string_literal: true
class SendItemChangeNotifications
  include Sidekiq::Worker

  def self.display_name
    'Sending an email notification of a modified item'
  end

  def perform(tag_filter_id, hub_id, current_user_id, items_to_process)
    tag_filter = TagFilter.find(tag_filter_id)
    hub = Hub.find(hub_id)
    user = User.find(current_user_id)

    tag_filter.notify_about_items_modification(hub, user, items_to_process)
  end
end
