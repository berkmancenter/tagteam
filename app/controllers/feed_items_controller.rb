class FeedItemsController < ApplicationController
  before_filter :load_hub_feed
  before_filter :load_feed_item, :except => [:index]
  before_filter :add_breadcrumbs, :except => [:index, :content]

  access_control do
    allow all
  end

  def content
    breadcrumbs.add @feed_item.title, hub_feed_feed_item_path(@hub_feed,@feed_item)
    respond_to do|format|
      format.html{ render :layout => ! request.xhr?}
    end
  end

  def index
    #@feed_items = @hub_feed.feed_items.paginate(:include => [:tags, :taggings, :feeds, :hub_feeds], :order => 'date_published desc', :page => params[:page], :per_page => get_per_page)
    @feed_items = @hub_feed.feed_items.paginate(:include => [:feeds, :hub_feeds], :order => 'date_published desc', :page => params[:page], :per_page => get_per_page)
    render :layout => ! request.xhr?
  end

  def show
    breadcrumbs.add @feed_item.title, hub_feed_feed_item_path(@hub_feed,@feed_item)
  end


  private

  def load_hub_feed
    @hub_feed = HubFeed.find(params[:hub_feed_id])
    @hub = @hub_feed.hub
  end

  def load_feed_item
    @feed_item = FeedItem.find(params[:id])
  end

  def add_breadcrumbs
    unless @hub_feed.blank?
      breadcrumbs.add @hub.to_s, hub_path(@hub) 
      breadcrumbs.add @hub_feed.to_s, hub_hub_feed_path(@hub,@hub_feed) 
    end
  end

end
