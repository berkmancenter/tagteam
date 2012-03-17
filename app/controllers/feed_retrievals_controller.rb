class FeedRetrievalsController < ApplicationController

  before_filter :load_hub_feed

  caches_action :index, :show, :unless => Proc.new{|c| current_user && current_user.is?(:owner, @hub)}, :expires_in => 15.minutes, :cache_path => Proc.new{ 
    request.fullpath + "&per_page=" + get_per_page
  }

  # A list of FeedRetrieval objects for the Feed referenced by a HubFeed. Returns html, json, or xml.
  def index
    breadcrumbs.add @hub_feed, hub_hub_feed_path(:hub_id => @hub, :id => @hub_feed)
    @feed_retrievals = @hub_feed.feed.feed_retrievals.paginate(:page => params[:page], :per_page => get_per_page)
    respond_to do|format|
    format.html{ render :layout => ! request.xhr? }
    format.json{ render_for_api :default, :json => @feed_retrievals }
    format.xml{ render_for_api :default, :xml => @feed_retrievals }
    end
  end

  # Detailed info about a FeedRetrieval. Returns html, json, or xml.
  def show
    breadcrumbs.add @hub, hub_path(@hub)
    breadcrumbs.add @hub_feed, hub_hub_feed_path(@hub, @hub_feed)
    @feed_retrieval = FeedRetrieval.find(params[:id])

    @new_items = FeedItem.paginate(:include => [:tags, :taggings, :feeds, :hub_feeds], :conditions => {:id => @feed_retrieval.new_feed_items}, :order => 'created_at desc',:page => params[:page], :per_page => get_per_page)
    @changed_items = FeedItem.paginate(:include => [:tags, :taggings, :feeds, :hub_feeds], :conditions => {:id => @feed_retrieval.changed_feed_items}, :order => 'created_at desc',:page => params[:page], :per_page => get_per_page)

    respond_to do|format|
      format.html{ render :layout => ! request.xhr? }
      format.json{ render_for_api :default, :json => @feed_retrieval}
      format.xml{ render_for_api :default, :xml => @feed_retrieval}
    end
  end

  private

  def load_hub_feed
    @hub_feed = HubFeed.find(params[:hub_feed_id])
    @hub = @hub_feed.hub
  end

end
