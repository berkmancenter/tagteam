# frozen_string_literal: true

module Admin
  # Homepage for admin features
  class HomeController < ApplicationController
    before_action :authenticate_user!

    after_action :verify_authorized

    def index
      authorize :admin_home, :index?

      breadcrumbs.add 'Admin Home', admin_root_path
    end
  end
end
