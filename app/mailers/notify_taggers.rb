class Notifications < ActionMailer::Base
  default from: Tagteam::Application.config.default_sender

  def modified_tag(taggers, hub, old_tag, type)
    @hub = hub
    @hub_url = hub_url(@hub)
    subject = 'XXX'
    mail(to: taggers.collect(&:email), subject: subject)
  end
end
