class NotificationsMailer < ActionMailer::Base
  default from: Tagteam::Application.config.default_sender,
    return_path: Tagteam::Application.config.return_path

  def user_data_import_completion_notification(email, status)
    @status = status

    subject = 'Import status'
    mail(cc: email, subject: subject)
  end
end
