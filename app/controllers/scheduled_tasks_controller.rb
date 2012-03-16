class ScheduledTasksController < ApplicationController
  protect_from_forgery :except => [:expire_cache, :update_feeds]
  before_filter :check_shared_key

  def update_feeds
    logger.warn('Update feeds')
    UpdateFeeds.perform
    render :text => "Updated feeds\n", :layout => false
  rescue Exception => e
    render :string => e.inspect, :status => :internal_server_error
  end

  def expire_cache
    logger.warn('Expire cache')
    ExpireFileCache.perform
    render :text => "Expired files from the cache\n", :layout => false
  rescue Exception => e
    render :string => e.inspect, :status => :internal_server_error
  end

  private

  def check_shared_key
    if params[:SHARED_KEY_FOR_TASKS].nil? || params[:SHARED_KEY_FOR_TASKS].gsub(/['"]/,'') != SHARED_KEY_FOR_TASKS
      flash[:notice] = 'Sorry, dear chap. You need to give me the shared key if you want to run scheduled tasks via a web request.'
      render :status => :not_acceptable,  :text => "Sorry, the SHARED_KEY_FOR_TASKS didn't match.\n", :layout => false and return
    end
  end

end
