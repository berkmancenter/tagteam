# frozen_string_literal: true
class ApplicationMailer < ActionMailer::Base
  default from: Tagteam::Application.config.default_sender

  layout 'mailer'
end
