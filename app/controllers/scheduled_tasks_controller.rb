# This is used to run scheduled tasks efficiently in a persistent Rails environment via cron. Yeah, we're already using Resque, but we'd have to run ANOTHER daemon for resque-scheduler scheduled tasks. We're already running redis, resque, sunspot and rails itself and it seems silly to run yet another daemon when cron is more than adequate.
# A SHARED_KEY_FOR_TASKS is required to be included along with the POST'd command - please see the file "doc/crontab.in" for example wget tasks that will properly invoke the jobs in this controller. The SHARED_KEY_FOR_TASKS is created in the proper location via db:seed during installation.
class ScheduledTasksController < ApplicationController
  protect_from_forgery :except => [:expire_cache, :update_feeds]
  before_filter :check_shared_key

  #Update feeds. You can also run this job via a regular old rake task, but it's a heckuva lost slower than using wget to POST to your running rails environment.
  def update_feeds
    logger.warn('Update feeds')
    Resque.enqueue(UpdateFeeds)
    render :text => "Updated feeds\n", :layout => false
  rescue Exception => e
    render :string => e.inspect, :status => :internal_server_error
  end


  #Expire the file cache via the ExpireFileCache class.
  def expire_cache
    logger.warn('Expire cache')
    Resque.enqueue(ExpireFileCache)
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
