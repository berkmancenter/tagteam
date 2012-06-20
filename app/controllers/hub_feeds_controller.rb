# Allow a Hub owner to add HubTagFilters.
class HubFeedsController < ApplicationController

  caches_action :controls, :index, :show, :more_details, :autocomplete, :unless => Proc.new{|c| current_user }, :expires_in => Tagteam::Application.config.default_action_cache_time, :cache_path => Proc.new{ 
    request.fullpath + "&per_page=" + get_per_page
  }

  access_control do
    allow all, :to => [:index, :show, :more_details, :autocomplete, :controls]
    allow :owner, :of => :hub
    allow :bookmarker, :of => :hub, :to => [:new, :create]
    allow :owner, :of => :hub_feed, :to => [:edit, :update, :destroy, :import, :reschedule_immediately]
    allow :superadmin
  end

  def controls
    load_hub_feed
    load_hub
    render :layout => ! request.xhr?
  end

  def autocomplete
    load_hub
    hub_id = @hub.id
    @search = HubFeed.search do
      with :hub_ids, hub_id
      fulltext params[:term]
    end

    @search.execute!

    respond_to do |format|
      format.json { 
        render :json => @search.results.collect{|r| {:id => r.id, :label => r.display_title} }
      }
    end
  rescue
    render :text => "Please try a different search term", :layout => ! request.xhr?
  end

  # Accepts an import upload in Connotea RDF and delicious bookmark export format. Creates a Resque job that does the actual importing, as it's pretty slow on larger collections - around 400 per minute or so.
  def import
    load_hub_feed
    load_hub
    if params[:type].blank? || params[:import_file].blank?
      flash[:notice] = 'Please select a file type and attach a file for importing.'
    else 
      file_name = Rails.root.to_s + '/tmp/incoming_import-' + Time.now.to_i.to_s

      FileUtils.cp(params[:import_file].tempfile,file_name)
      Resque.enqueue(ImportFeedItems,@hub_feed.id, current_user.id, file_name,params[:type])

      flash[:notice] = 'The file has been uploaded and scheduled for import. Please see the "background jobs" link in the footer to track progress.'
    end
    redirect_to :action => :show
  end

  def more_details
    load_hub_feed
    load_hub
    render :layout => ! request.xhr?
  end

  def reschedule_immediately
    load_hub_feed
    load_hub
    feed = @hub_feed.feed
    feed.next_scheduled_retrieval = Time.now
    feed.save
    flash[:notice] = 'Rescheduled that feed to be re-indexed at the next available opportunity.'
    redirect_to hub_hub_feed_path(@hub,@hub_feed)
  rescue
    flash[:notice] = "We couldn't reschedule that feed."
    redirect_to hub_hub_feed_path(@hub,@hub_feed)
  end

  def index
    load_hub
    @hub_feeds = @hub.hub_feeds.rss.paginate(:page => params[:page], :per_page => get_per_page, :order => 'created_at desc' )
    respond_to do|format|
      format.html{ render :layout => ! request.xhr? }
      format.json{ render_for_api :default, :json => @hub_feeds }
      format.xml{ render_for_api :default, :xml => @hub_feeds }
    end
  end

  def show
    load_hub_feed
    load_hub
    add_breadcrumbs
    @show_auto_discovery_params = hub_feed_feed_items_url(@hub_feed, :format => :rss)
    breadcrumbs.add @hub_feed.display_title, hub_hub_feed_path(@hub,@hub_feed)
  end

  def new
    load_hub
    # Only used to create bookmarking collections.
    # Actual rss feeds are added through the hub controller. Yeah, probably not optimal
    @hub_feed = HubFeed.new
    @hub_feed.hub_id = @hub.id
  end

  def create
    load_hub
    # Only used to create bookmarking collections.
    # Actual rss feeds are added through the hub controller. Yeah, probably not optimal
    @hub_feed = HubFeed.new
    @hub_feed.hub_id = @hub.id

    actual_feed = Feed.new
    actual_feed.bookmarking_feed = true
    actual_feed.feed_url = 'not applicable'
    actual_feed.title = params[:hub_feed][:title]
    current_user.has_role!(:owner, actual_feed)
    actual_feed.save

    @hub_feed.feed = actual_feed
    @hub_feed.attributes = params[:hub_feed]
    respond_to do|format|
      if @hub_feed.save
        current_user.has_role!(:editor, @hub_feed)
        current_user.has_role!(:owner, @hub_feed)
        flash[:notice] = 'Created that bookmarking collection.'
        format.html {redirect_to hub_path(@hub)}
      else
        flash[:error] = 'Couldn\'t create that bookmarking collection!'
        format.html {render :action => :new}
      end
    end
  end

  def update
    load_hub_feed
    load_hub
    @hub_feed.attributes = params[:hub_feed]
    respond_to do|format|
      if @hub_feed.save
        current_user.has_role!(:editor, @hub_feed)
        flash[:notice] = 'Updated that feed.'
        format.html {redirect_to hub_path(@hub)}
      else
        flash[:error] = 'Couldn\'t update that feed!'
        format.html {render :action => :new}
      end
    end
  end

  def edit
    load_hub_feed
    load_hub
    add_breadcrumbs
  end

  def destroy
    load_hub_feed
    load_hub
    @hub_feed.destroy
    flash[:notice] = 'Removed it. It\'ll take a few minutes depending on how many items were in this feed.'
    redirect_to(hub_path(@hub))
  rescue
    flash[:error] = "Couldn't remove that feed."
    redirect_to(hub_path(@hub))
  end

  private

  def load_hub_feed
    @hub_feed = HubFeed.find_by_id(params[:id])
  end

  def load_hub
    unless @hub_feed.blank?
      @hub = @hub_feed.hub
    else
      @hub = Hub.find(params[:hub_id])
    end
  end

  def add_breadcrumbs
    breadcrumbs.add @hub.title, hub_path(@hub)
  end

end
