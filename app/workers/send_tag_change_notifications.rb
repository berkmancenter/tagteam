# frozen_string_literal: true
class SendTagChangeNotifications
  include Sidekiq::Worker

  def self.display_name
    'Sending an email notification of a modified tag'
  end

  def perform(tag_filter_id, tag_id, new_tag_id, scope_class, scope_id, hub_id, hub_feed_id, current_user_id)
    tag_filter = TagFilter.find(tag_filter_id)
    tag = ActsAsTaggableOn::Tag.find(tag_id)
    new_tag = ActsAsTaggableOn::Tag.find(new_tag_id)
    scope_model = scope_class.constantize
    scope = scope_model.find(scope_id)
    hub = Hub.find(hub_id)
    hub_feed = HubFeed.where(id: hub_feed_id).first
    user = User.find(current_user_id)

    tag_filter.notify_taggers(
      tag,
      new_tag,
      scope,
      hub,
      hub_feed,
      user
    )
  end
end
