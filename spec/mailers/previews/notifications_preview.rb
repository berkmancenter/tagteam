# frozen_string_literal: true
class NotificationsPreview < ActionMailer::Preview
  def item_change_notification
    hub = Hub.first
    modified_item = hub.feed_items.first
    item_users = [User.first]
    current_user = User.first
    changes = { tags_modified: %w(tag1 tag2) }

    Notifications.item_change_notification(hub, modified_item, item_users, current_user, changes)
  end

  def tag_change_notification
    modify_tag_filter = ModifyTagFilter.last
    taggers_to_notify = [User.first]
    hub = Hub.first
    old_tag = modify_tag_filter.tag
    new_tag = modify_tag_filter.new_tag
    current_user = User.first
    scope = hub.hub_feeds.last

    Notifications.tag_change_notification(
      taggers_to_notify,
      hub,
      old_tag,
      new_tag,
      current_user,
      scope
    )
  end
end
