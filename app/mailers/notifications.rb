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
end
