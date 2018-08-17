# frozen_string_literal: true
class ApplicationMailer < ActionMailer::Base
  default from: Tagteam::Application.config.default_sender,
    return_path: Tagteam::Application.config.return_path

  layout 'mailer'
end
