# frozen_string_literal: true
# Preview all emails at http://localhost:3000/rails/mailers/admin/user_approvals_mailer
module Admin
  class UserApprovalsMailerPreview < ActionMailer::Preview
    def notify_admin_of_signup
      UserApprovalsMailer.notify_admin_of_signup(User.last)
    end

    def notify_user_of_approval
      UserApprovalsMailer.notify_user_of_approval(User.last)
    end

    def notify_user_of_denial
      UserApprovalsMailer.notify_user_of_denial(User.last)
    end
  end
end
