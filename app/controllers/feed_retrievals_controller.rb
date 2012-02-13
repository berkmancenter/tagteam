class FeedRetrievalsController < ApplicationController

  before_filter :load_hub_feed

  def index
    breadcrumbs.add @hub_feed, hub_hub_feed_path(:hub_id => @hub, :id => @hub_feed)
    @feed_retrievals = @hub_feed.feed.feed_retrievals
    render :layout => ! request.xhr?
  end

  def show
    @feed_retrieval = FeedRetrieval.find(params[:id])
  end

  private

  def load_hub_feed
    @hub_feed = HubFeed.find(params[:hub_feed_id])
    @hub = @hub_feed.hub
  end

end
