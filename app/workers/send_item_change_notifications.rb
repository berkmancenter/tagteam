# frozen_string_literal: true
class SendItemChangeNotifications
  include Sidekiq::Worker

  def self.display_name
    'Sending an email notification of a modified item'
  end

  def perform(scope_class, scope_id, hub_id, current_user_id, items_to_process, changes)
    hub = Hub.find(hub_id)
    user = User.find(current_user_id)
    scope_model = scope_class.constantize
    scope = scope_model.find(scope_id)

    scope.notify_about_items_modification(hub, user, items_to_process, changes)
  end
end
