# frozen_string_literal: true
class FeedRetrievalsController < ApplicationController
  caches_action :index, :show, unless: proc { |_c| current_user }, expires_in: Tagteam::Application.config.default_action_cache_time, cache_path: proc {
    Digest::MD5.hexdigest(request.fullpath + '&per_page=' + get_per_page)
  }

  # A list of FeedRetrieval objects for the Feed referenced by a HubFeed. Returns html, json, or xml.
  def index
    load_hub_feed
    breadcrumbs.add @hub, hub_path(@hub, @hub_feed)
    breadcrumbs.add @hub_feed, hub_hub_feed_path(@hub, @hub_feed)
    @feed_retrievals = @hub_feed.feed.feed_retrievals.paginate(page: params[:page], per_page: get_per_page)
    respond_to do |format|
      format.html { render layout: request.xhr? ? false : 'tabs' }
      format.json { render_for_api :default, json: @feed_retrievals }
      format.xml { render_for_api :default, xml: @feed_retrievals }
    end
  end

  # Detailed info about a FeedRetrieval. Returns html, json, or xml.
  def show
    load_hub_feed
    breadcrumbs.add @hub, hub_path(@hub)
    breadcrumbs.add @hub_feed, hub_hub_feed_path(@hub, @hub_feed)
    @feed_retrieval = FeedRetrieval.find(params[:id])

    @new_items =
      FeedItem
      .where(id: @feed_retrieval.new_feed_items)
      .order(created_at: :desc)
      .includes(:tags, :taggings, :feeds, :hub_feeds)
      .paginate(page: params[:page], per_page: get_per_page)

    @changed_items =
      FeedItem
      .where(id: @feed_retrieval.changed_feed_items)
      .order(created_at: :desc)
      .includes(:tags, :taggings, :feeds, :hub_feeds)
      .paginate(page: params[:page], per_page: get_per_page)

    respond_to do |format|
      format.html { render layout: request.xhr? ? false : 'tabs' }
      format.json { render_for_api :default, json: @feed_retrieval }
      format.xml { render_for_api :default, xml: @feed_retrieval }
    end
  end

  private

  def load_hub_feed
    if params.has_key?(:username)
      @hub = Hub.find(params[:hub_id])
      @user = User.find_by(username: params[:username])
      @hub_feed = @hub.hub_feeds.detect { |hf| hf.creators.include?(@user) }
    else
      @hub_feed = HubFeed.find(params[:hub_feed_id])
      @hub = @hub_feed.hub
    end
  end
end
