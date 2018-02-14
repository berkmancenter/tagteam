# frozen_string_literal: true

class FeedItemsController < ApplicationController
  caches_action :controls, :content, :related, :index, :show, unless: proc { |_c| current_user }, expires_in: Tagteam::Application.config.default_action_cache_time, cache_path: proc {
    Digest::MD5.hexdigest(request.fullpath + '&per_page=' + get_per_page)
  }

  protect_from_forgery except: :index

  before_action :set_hub_feed, except: [:tag_list]
  before_action :set_feed_item, except: [:index]

  def controls
    add_breadcrumbs
    render layout: !request.xhr?
  end

  # Return the full content for a FeedItem,, this could potentially be a large amount of content. Returns html, json, or xml. Action cached for anonymous visitors.
  def content
    add_breadcrumbs
    respond_to do |format|
      format.html { render layout: request.xhr? ? false : 'tabs' }
      format.json { render_for_api :with_content, json: @feed_item }
      format.xml { render_for_api :with_content, xml: @feed_item }
    end
  end

  def about
    add_breadcrumbs
    respond_to do |format|
      format.html { render layout: request.xhr? ? false : 'tabs' }
      format.json { render_for_api :default, json: @feed_item }
      format.xml { render_for_api :default, xml: @feed_item }
    end
  end

  # Uses a solr more_like_this query to find items to related to this one by comparing the title and tag list. Returns html, json, or xml. Action cached for anonymous visitors.
  def related
    add_breadcrumbs
    hub_id = @hub.id
    @related = Sunspot.more_like_this(@feed_item) do
      fields :title, :tag_list
      with :hub_ids, hub_id
      minimum_word_length 3
      paginate page: params[:page], per_page: get_per_page
    end

    respond_to do |format|
      format.html do
        template = params[:view] == 'grid' ? 'related_grid' : 'related'
        render template, layout: request.xhr? ? false : 'tabs'
      end
      format.json { render_for_api :default, json: @related.blank? ? [] : @related.results }
      format.xml { render_for_api :default, xml: @related.blank? ? [] : @related.results }
    end
  end

  # A paginated list of FeedItems in a HubFeed. Returns html, atom, rss, json, or xml. Action cached for anonymous visitors.
  def index
    Feeds::StoreFeedVisitorJob.perform_later(
      request.path,
      request.format.symbol.to_s,
      request.remote_ip,
      request.user_agent
    )

    @show_auto_discovery_params = hub_feed_feed_items_url(@hub_feed, format: :rss)
    @feed_items =
      @hub_feed
      .feed_items
      .includes(:feeds, :hub_feeds)
      .order(date_published: :desc, created_at: :desc)
      .paginate(page: params[:page], per_page: get_per_page)
    breadcrumbs.add @hub_feed.hub, hub_path(@hub_feed.hub)
    breadcrumbs.add @hub_feed.feed, hub_hub_feed_path(@hub_feed.hub, @hub_feed)
    respond_to do |format|
      format.html do
        template = params[:view] == 'grid' ? 'feed_items/index_grid' : 'feed_items/index'
        render template, layout: request.xhr? ? false : 'tabs'
      end
      format.atom {}
      format.rss {}
      format.json { render_for_api :default, json: @feed_items }
      format.xml { render_for_api :default, xml: @feed_items }
    end
  end

  # A FeedItem. Returns html, json, or xml. Action cached for anonymous visitors.
  def show
    add_breadcrumbs
    respond_to do |format|
      format.html do
        render layout: request.xhr? ? false : 'tabs'
      end
      format.json { render_for_api :with_content, json: @feed_item }
      format.xml { render_for_api :with_content, xml: @feed_item }
    end
  end

  def tag_list
    @hub = Hub.find(params[:hub_id])
    respond_to do |format|
      format.html do
        render layout: request.xhr? ? false : 'tabs'
      end
    end
  end

  def edit
    authorize @feed_item

    add_breadcrumbs

    render layout: 'tabs'
  end

  def update
    authorize @feed_item

    inputs = { feed_item: @feed_item, hub: @hub, user: current_user }.reverse_merge(feed_item_params)
    outcome = FeedItems::Update.run(inputs)

    if outcome.valid?
      redirect_to hub_feed_feed_item_path(@hub_feed, @feed_item)
    else
      @feed_item = outcome

      render :edit
    end
  end

  private

  def set_hub_feed
    @hub_feed = HubFeed.find(params[:hub_feed_id])
    @hub = @hub_feed.hub
  end

  def set_feed_item
    @feed_item = FeedItem.find(params[:id])
  end

  def from_search?
    request.referer && request.referer.include?('item_search')
  end

  def add_breadcrumbs
    if from_search?
      breadcrumbs.add @hub.to_s, hub_path(@hub)
      breadcrumbs.add 'Search', request.referer
    else
      if @hub_feed.present?
        breadcrumbs.add @hub.to_s, hub_path(@hub)
        breadcrumbs.add @hub_feed.to_s, hub_hub_feed_path(@hub, @hub_feed)
        if from_search?
          breadcrumbs.add @feed_item.to_s
        else
          breadcrumbs.add @feed_item.to_s, hub_feed_feed_item_path(@hub_feed, @feed_item)
        end
      end
    end
  end

  def feed_item_params
    params.require(:feed_item).permit(:description, :title, :url)
  end
end
