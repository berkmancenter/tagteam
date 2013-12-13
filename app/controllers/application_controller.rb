class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :init_breadcrumbs

  layout :layout_by_resource

  # The per_page setting for pagination can be overrided by cgi parameters but will fall back to the cookie "per_page" or ultimately the default_tagteam_per_page config entry defined in config/tagteam.yml
  def get_per_page
    params[:per_page] || cookies[:per_page] || Tagteam::Application.config.default_tagteam_per_page.to_s
  end

  # Switch the layout when logging in via the bookmarklet.
  def layout_by_resource
    if devise_controller? && resource_name == :user && action_name == 'new' && (session[:user_return_to] && session[:user_return_to].match(/bookmarklet/))
      "bookmarklet"
    else
      "application"
    end
  end

  rescue_from Acl9::AccessDenied do |exception|
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

  private 
  def init_breadcrumbs
    breadcrumbs.add 'Home', root_path
  end
end
