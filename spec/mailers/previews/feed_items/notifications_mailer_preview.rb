module FeedItems
  class NotificationsMailerPreview < ActionMailer::Preview
    def feed_item_change_notification
      hub = Hub.first
      modified_item = hub.feed_items.first
      item_users = [User.first]
      current_user = User.first
      changes = {
        description: ['old description', 'new description'],
        title: ['old title', 'new title'],
        url: ['https://thing1.com', 'https://thing2.com']
      }

      NotificationsMailer.feed_item_change_notification(
        hub: hub,
        modified_item: modified_item,
        users_to_notify: item_users,
        current_user: current_user,
        changes: changes
      )
    end
  end
end
