# frozen_string_literal: true

# mailer to send messages to hub members
class MessagesMailer < ActionMailer::Base
  default from: Tagteam::Application.config.default_sender

  def send_message(recipients, subject, body)
    mail(to: recipients, subject: subject, body: body)
  end
end
