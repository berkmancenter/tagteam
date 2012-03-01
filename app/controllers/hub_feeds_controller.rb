class HubFeedsController < ApplicationController
  before_filter :load_hub_feed, :except => [:index, :new, :create, :autocomplete]
  before_filter :load_hub
  before_filter :add_breadcrumbs, :except => [:index, :new, :create, :reschedule_immediately, :autocomplete]
  before_filter :prep_resources

  access_control do
    allow all, :to => [:index, :show, :more_details, :autocomplete]
    allow :owner, :of => :hub, :to => [:new, :create, :reschedule_immediately]
    allow :owner, :of => :hub_feed, :to => [:edit, :update, :destroy]
    allow :superadmin, :hub_feed_admin
  end

  def autocomplete
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
  end

  def more_details
    render :layout => ! request.xhr?
  end

  def reschedule_immediately
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
    @hub_feeds = @hub.hub_feeds.paginate(:include => [ :feed ], :page => params[:page], :per_page => get_per_page, :order => 'created_at desc' )
    respond_to do|format|
      format.html{
        render :layout => ! request.xhr? 
      }
    end
  end

  def show
    @show_auto_discovery_params = hub_feed_feed_items_url(@hub_feed, :format => :rss)
    breadcrumbs.add @hub_feed.display_title, hub_hub_feed_path(@hub,@hub_feed)
  end

  def new
  end

  def create
  end

  def update
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
  end

  def destroy
    @hub_feed.destroy
    flash[:notice] = 'Removed that feed.'
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
    @hub = Hub.find(params[:hub_id])
  end

  def prep_resources
  end

  def add_breadcrumbs
    breadcrumbs.add @hub.title, hub_path(@hub)
  end

end
