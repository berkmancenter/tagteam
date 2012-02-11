class RepublishedFeedsController < ApplicationController
  before_filter :load_republished_feed, :except => [:new, :create, :index]
  before_filter :load_hub, :only => [:new, :create, :index]
  before_filter :prep_resources
  before_filter :register_breadcrumb

  access_control do
    allow all, :to => [:index, :show, :rss, :atom, :items, :inputs, :removals]
    allow :owner, :of => :hub, :to => [:new, :create]
    allow :owner, :of => :republished_feed, :to => [:edit, :update, :destroy]
    allow :superadmin, :republished_feed_admin
  end

  def index
    @republished_feeds = @hub.republished_feeds
    respond_to do|format|
      format.html{
        render :layout => ! request.xhr? 
      }
    end
  end

  def show
    @owners = @republished_feed.owners
    @hub = @republished_feed.hub
#    @republished_feed.items
  end

  def items
    @search = @republished_feed.item_search
    unless @search.blank?
      @search.build do
        paginate :page => params[:page], :per_page => params[:per_page]
      end
      @search.execute!
    end
    render :layout => ! request.xhr?
  end

  def inputs
    render :layout => ! request.xhr?
  end

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

  def rss
  end

  def atom
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

  def prep_resources
#    @javascripts_extras = ['republished_feeds']
  end

  def register_breadcrumb
    breadcrumbs.add @hub.title, hub_path(@hub)
  end

end
