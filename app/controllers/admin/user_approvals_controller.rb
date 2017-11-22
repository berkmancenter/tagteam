# frozen_string_literal: true

module Admin
  # Controller for admins to approve/reject user signups
  class UserApprovalsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_user, only: %i[approve deny]

    after_action :verify_authorized

    def index
      authorize :user_approval

      breadcrumbs.add 'Admin', admin_users_path
      breadcrumbs.add 'User Approvals', admin_user_approvals_path

      @unapproved_users = User.unapproved
    end

    def approve
      flash[:notice] = "Access for #{@user.email} has been approved."

      @user.update!(approved: true)

      UserApprovalsMailer.notify_user_of_approval(@user).deliver_later

      redirect_to action: :index
    end

    def deny
      flash[:notice] = "Access for #{@user.email} has been denied and their user record has been deleted."

      @user.destroy!

      UserApprovalsMailer.notify_user_of_denial(@user.email).deliver_later

      redirect_to action: :index
    end

    private

    def set_user
      @user = User.find(params[:user_approval_id])

      authorize :user_approval
    end
  end
end
