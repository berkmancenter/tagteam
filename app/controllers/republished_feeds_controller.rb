class RepublishedFeedsController < ApplicationController
  before_filter :load_republished_feed, :except => [:new, :create]
  before_filter :load_hub, :only => [:new, :create]
  before_filter :prep_resources
  before_filter :register_breadcrumb

  access_control do
    allow all, :to => [:show, :rss, :atom]
    allow :owner, :of => :hub, :to => [:new, :create]
    allow :owner, :of => :republished_feed, :to => [:edit, :update, :destroy]
    allow :superadmin, :republished_feed_admin
  end

  def show
    @owners = @republished_feed.owners
#    @republished_feed.items
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
