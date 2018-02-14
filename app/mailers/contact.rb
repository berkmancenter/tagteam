# frozen_string_literal: true

class Contact < ActionMailer::Base
  default from: Tagteam::Application.config.default_sender

  def request_rights(params, hub)
    @hub = hub
    @params = params
    @hub_url = hub_url(@hub)
    subject = params[:contact][:rights].length == 1 ? "Feedback submission about your hub - #{@hub}" : "A request for rights to collaborate in your hub - #{@hub}"
    mail(:to => @hub.owners.collect(&:email), :subject => subject, 'reply-to' => params[:contact][:email])
  end
end
