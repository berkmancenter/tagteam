class RepublishedFeedsController < ApplicationController
  before_filter :load_republished_feed, :except => [:new, :create, :index]
  before_filter :load_hub, :only => [:new, :create, :index]
  before_filter :register_breadcrumb

  caches_action :index, :show, :items, :inputs, :removals, :more_details, :unless => Proc.new{|c| current_user && current_user.is?(:owner, @hub)}, :expires_in => DEFAULT_ACTION_CACHE_TIME, :cache_path => Proc.new{ 
    request.fullpath + "&per_page=" + get_per_page
  }

  access_control do
    allow all, :to => [:index, :show, :items, :inputs, :removals, :more_details]
    allow :owner, :of => :hub, :to => [:new, :create]
    allow :owner, :of => :republished_feed, :to => [:edit, :update, :destroy]
    allow :superadmin, :republished_feed_admin
  end

  def more_details
    render :layout => ! request.xhr?
  end

  # A list of RepublishedFeeds (aka "remixed feeds") in a hub. Returns html, json, and xml.
  def index
    @republished_feeds = @hub.republished_feeds.paginate(:page => params[:page], :per_page => get_per_page)
    respond_to do|format|
      format.html{ render :layout => ! request.xhr? }
      format.json{ render_for_api :default, :json => @republished_feeds }
      format.xml{ render_for_api :default, :xml => @republished_feeds }
    end
  end

  # An individual RepublishedFeed. Returns html, json, and xml.
  def show
    @show_auto_discovery_params = items_hub_republished_feed_url(@hub, @republished_feed, :format => :rss)
    @owners = @republished_feed.owners
    @hub = @republished_feed.hub
#    @republished_feed.items
    respond_to do |format|
      format.html{ render :layout => ! request.xhr? }
      format.json{ render_for_api :default, :json => @republished_feed }
      format.xml{ render_for_api :default, :xml => @republished_feed }
    end
  end

  # A paginated list of FeedItems in this RepublishedFeed. Returns html, rss, atom, json, and xml. 
  def items
    @show_auto_discovery_params = items_hub_republished_feed_url(@hub, @republished_feed, :format => :rss)
    @search = @republished_feed.item_search
    unless @search.blank?
      @search.build do
        paginate :page => params[:page], :per_page => get_per_page
      end
      @search.execute!
    end
    respond_to do |format|
      format.html{ render :layout => ! request.xhr? }
      format.rss{ }
      format.atom{ }
      format.json{ render_for_api :default,  :json => (@search.blank?) ? [] : @search.results }
      format.xml{ render_for_api :default,  :xml => (@search.blank?) ? [] : @search.results }
    end
  end

  # List the InputSource objects that add items to this RepublishedFeed.
  def inputs
    render :layout => ! request.xhr?
  end

  # List the InputSource objects that remove items from this RepublishedFeed.
  def removals
    render :layout => ! request.xhr?
  end

  def new
    @republished_feed = RepublishedFeed.new(:hub_id => @hub.id)
  end

  def create
    @republished_feed = RepublishedFeed.new(:hub_id => @hub.id)
    @republished_feed.attributes = params[:republished_feed]
    respond_to do|format|
      if @republished_feed.save
        current_user.has_role!(:owner, @republished_feed)
        current_user.has_role!(:creator, @republished_feed)
        flash[:notice] = 'Created a new republished feed. You should switch to the "inputs" tab and add items for publishing.'
        format.html{redirect_to :action => :show, :id => @republished_feed.id}
      else
        flash[:error] = 'Could not add that republished feed'
        format.html {render :action => :new}
      end
    end
  end

  def update
    @republished_feed.attributes = params[:republished_feed]
    respond_to do|format|
      if @republished_feed.save
        current_user.has_role!(:editor, @republished_feed)
        flash[:notice] = 'Edited that republished feed'
        format.html{redirect_to :action => :show, :id => @republished_feed.id}
      else
        flash[:error] = 'Could not edit that republished feed'
        format.html {render :action => :update}
      end
    end
  end

  def edit
  end

  def destroy
    @republished_feed.destroy
    flash[:notice] = 'Removed that feed.'
    redirect_to(hub_path(@hub))
  rescue
    flash[:error] = "Couldn't remove that feed."
    redirect_to(hub_path(@hub))
  end

  private

  def load_hub
    hub_id = (params[:republished_feed].blank?) ? params[:hub_id] : params[:republished_feed][:hub_id]
    @hub = Hub.find(hub_id)
  end

  def load_republished_feed
    @republished_feed = RepublishedFeed.find(params[:id])
    @hub = @republished_feed.hub
  end

  def register_breadcrumb
    breadcrumbs.add @hub.title, hub_path(@hub)
  end

end
