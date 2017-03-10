# frozen_string_literal: true
module Users
  # Override Devise's RegistrationsController
  class RegistrationsController < Devise::RegistrationsController
    def create
      super do |resource|
        Admin::UserApprovalsMailer.notify_admin_of_signup(resource).deliver_later unless resource.edu_email?
      end
    end
  end
end
