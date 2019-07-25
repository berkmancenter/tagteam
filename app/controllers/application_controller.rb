# frozen_string_literal: true
class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery with: :exception
  before_action :configure_devise_permitted_parameters, if: :devise_controller?
  before_action :init_breadcrumbs

  layout :layout_by_resource

  helper_method :get_per_page

  # The per_page setting for pagination can be overrided by cgi parameters but will fall back to the cookie "per_page" or ultimately the default_tagteam_per_page config entry defined in config/tagteam.yml
  def get_per_page
    per_page = params[:per_page] || cookies[:per_page] || Tagteam::Application.config.default_tagteam_per_page.to_s
    per_page = (per_page.to_i - 1).to_s if params[:view] && params[:view] == 'grid' && per_page.to_i.odd?
    per_page
  end

  # Switch the layout when logging in via the bookmarklet.
  def layout_by_resource
    if devise_controller? && resource_name == :user && action_name == 'new' && (session[:user_return_to] && session[:user_return_to].match(/bookmarklet/))
      'bookmarklet'
    else
      'application'
    end
  end

  rescue_from StandardError, with: :render_500 unless Rails.env.development?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  rescue_from Acl9::AccessDenied do |_exception|
    if current_user.blank?
      flash[:notice] = 'Please log in'
      session[:user_return_to] = request.original_url
      redirect_to new_user_session_path
    else
      flash[:notice] = "You can't access that - sorry!"
      redirect_to root_path
    end
  end

  def find_or_create_tag_by_name(name)
    ActsAsTaggableOn::Tag.find_or_create_by_name_normalized(name)
  end

  def render_500(exception)
    logger.info exception.backtrace.join("\n")

    respond_to do |format|
      format.html { render template: 'errors/500', layout: 'layouts/application', status: 500 }
      format.all { render nothing: true, status: 500 }
    end
  end

  private

  def init_breadcrumbs
    breadcrumbs.add 'Home', root_path
  end

  def user_not_authorized
    logger.warn "User #{current_user.id} not authorized for request: #{request}"
    flash[:alert] = "You can't access that - sorry!"
    redirect_to root_path
  end

  def configure_devise_permitted_parameters
    actions = [:account_update, :sign_in, :sign_up]
    keys = [:email, :terms_of_service, :username, :signup_reason]

    actions.each { |action| devise_parameter_sanitizer.permit(action, keys: keys) }
  end
end
