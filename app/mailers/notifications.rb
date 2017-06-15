class Notifications < ActionMailer::Base
  default from: Tagteam::Application.config.default_sender

  def tag_change_notification(taggers, hub, old_tag, new_tag, updated_by, scope)
    logger.info('Sending a notification about a tags change to ' + taggers.collect(&:email).join(','))

    @hub = hub
    @hub_url = hub_url(@hub)
    @old_tag = old_tag
    @new_tag = new_tag
    @updated_by = updated_by
    @scope = scope
    @scope_url = determine_url(@hub, @scope)

    subject = 'Tag update in the ' + @hub.title + ' hub'
    mail(bcc: taggers.collect(&:email), subject: subject)
  end

  def item_change_notification(hub, modified_item, item_users, current_user, changes)
    logger.info('Sending a notification about an items change to ' + item_users.collect(&:email).join(','))

    @hub = hub
    @hub_url = hub_url(@hub)
    @modified_item = modified_item
    @hub_feed = @hub.hub_feed_for_feed_item(@modified_item)
    @updated_by = current_user
    @changes = parse_changes(changes)

    subject = 'Item update in the ' + @hub.title + ' hub'
    mail(bcc: item_users.collect(&:email), subject: subject)
  end

  def user_data_import_completion_notification(email, status)
    @status = status

    subject = 'Import status'
    mail(cc: email, subject: subject)
  end

  private

  def parse_changes(changes)
    change_type, tags = changes.first

    case change_type
    when :tags_added
      "Tags added: #{tags.join(', ')}"
    when :tags_modified
      "Tags modified: #{tags.first} was changed to #{tags.last}"
    when :tags_deleted
      "Tags deleted: #{tags.join(', ')}"
    end
  end

  def determine_url(hub, scope)
    case scope
    when Hub
      hub_url(scope)
    when HubFeed
      hub_feed_feed_items_url(scope)
    when FeedItem
      hub_feed_item_url(hub, scope)
    end
  end
end
