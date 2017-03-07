# frozen_string_literal: true
module Admin
  # Send notification emails about user approval actions
  class UserApprovalsMailer < ApplicationMailer
    def notify_admin_of_signup(unapproved_user)
      @unapproved_user = unapproved_user
      superadmin_emails = User.superadmin.pluck(:email)

      mail(
        to: superadmin_emails,
        subject: 'TagTeam: User signup awaiting approval'
      )
    end

    def notify_user_of_approval(user)
      @user = user

      mail(to: user.email, subject: 'TagTeam: Signup approved')
    end

    def notify_user_of_denial(user)
      @user = user

      mail(to: user.email, subject: 'TagTeam: Signup denied')
    end
  end
end
