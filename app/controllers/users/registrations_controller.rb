# frozen_string_literal: true

module Users
  # Override Devise's RegistrationsController
  class RegistrationsController < Devise::RegistrationsController
    before_action :set_setting

    def create
      super do |resource|
        if notify_for_resource?(resource)
          Admin::UserApprovalsMailer.notify_admin_of_signup(resource).deliver_later
        end
      end
    end

    private

    def notify_for_resource?(resource)
      resource.persisted? && !resource.approved
    end

    def set_setting
      @setting = Admin::Setting.first_or_initialize
    end
  end
end
