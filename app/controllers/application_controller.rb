class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :init_breadcrumbs

  def get_per_page
    cookies[:per_page] || DEFAULT_TAGTEAM_PER_PAGE
  end

  private 
  def init_breadcrumbs
    breadcrumbs.add 'Home', root_path
  end
end
