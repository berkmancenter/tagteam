class Notifications < ActionMailer::Base
  default from: Tagteam::Application.config.default_sender

  def tag_change_notification(taggers, hub, old_tag, new_tag, updated_by)
    @hub = hub
    @hub_url = hub_url(@hub)
    @old_tag = old_tag
    @new_tag = new_tag
    @updated_by = updated_by

    subject = 'Tag update in the ' + @hub.title + ' hub'
    mail(bcc: taggers.collect(&:email), subject: subject)
  end

  def item_change_notification(hub, modified_item, item_users, current_user)
    @hub = hub
    @hub_url = hub_url(@hub)
    @modified_item = modified_item
    @updated_by = current_user

    subject = 'Item update in the ' + @hub.title + ' hub'
    mail(bcc: item_users.collect(&:email), subject: subject)
  end

  def user_data_import_completion_notification(email, status)
    @status = status

    subject = 'Import status'
    mail(cc: email, subject: subject)
  end
end
