# frozen_string_literal: true

# mailer to send messages to hub members
class MessagesMailer < ActionMailer::Base
  default from: Tagteam::Application.config.default_sender,
    return_path: Tagteam::Application.config.return_path

  def send_message(recipient, subject, body)
    mail(to: recipient, subject: subject, body: body)
  end
end
