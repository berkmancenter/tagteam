class HubFeedsController < ApplicationController
  before_filter :load_hub_feed, :except => [:index, :new, :create]
  before_filter :prep_resources

  access_control do
    allow all, :to => [:index, :show]
    allow :owner, :of => :hub, :to => [:new, :create]
    allow :owner, :of => :hub_feed, :to => [:edit, :update, :destroy]
    allow :superadmin, :hub_feed_admin
  end

  def index
    @hub_feeds = HubFeed.paginate(:order => 'updated_at desc', :page => params[:page], :per_page => params[:per_page]) 

  end

  def show
    @feed_items = @hub_feed.feed.feed_items.paginate(:order => 'updated_at desc', :page => params[:page], :per_page => params[:per_page])
  end

  def new
  end

  def create
  end

  def update
  end

  def edit
  end

  def destroy
  end

  private

  def load_hub_feed
    # Yes, on purpose to avoid the error. There are some actions in here that don't have to run in hub context.
    @hub = Hub.find_by_id(params[:hub_id])
    @hub_feed = HubFeed.find_by_id(params[:id])
  end

  def prep_resources
  end

end
