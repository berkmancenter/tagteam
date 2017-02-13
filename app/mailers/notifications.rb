class NotifyTaggers < ActionMailer::Base
  default from: Tagteam::Application.config.default_sender

  def process(taggers, hub, old_tag, type)
    @hub = hub
    @hub_url = hub_url(@hub)
    subject = 'XXX'
    mail(:to => @hub.owners.collect(&:email), :subject => subject, 'reply-to' => params[:contact][:email])
  end
end
