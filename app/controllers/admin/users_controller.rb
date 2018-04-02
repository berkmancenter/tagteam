# frozen_string_literal: true

module Admin
  # Controller for admins to see existing users in the system
  class UsersController < ApplicationController
    before_action :authenticate_user!
    before_action :set_sort, only: :index

    after_action :verify_authorized

    def index
      authorize User

      @order =  params[:order] || 'asc'

      breadcrumbs.add 'Admin', admin_root_path
      breadcrumbs.add 'Users', admin_users_path

      @users = Users::Sort.run!(users: policy_scope(User), sort_method: @sort, order: @order)
      @users = @users.reverse if @order == 'desc'
      @users = @users.paginate(page: params[:page], per_page: get_per_page)
    end

    private

    def set_sort
      @sort =
        if %w[application\ roles confirmed locked owned\ hubs username last\ sign\ in\ at date\ account\ created].include?(params[:sort])
          params[:sort]
        else
          'username'
        end
    end
  end
end
