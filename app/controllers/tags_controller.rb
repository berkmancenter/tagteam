# frozen_string_literal: true
class TagsController < ApplicationController
  before_action :load_hub
  before_action :load_tag_from_name, only: [:rss, :atom, :show, :json, :xml]
  before_action :load_feed_items_for_rss, only: [:rss, :atom, :json, :xml]
  before_action :add_breadcrumbs
  before_action :set_prefixed_tags, only: [:index]

  caches_action :rss, :atom, :json, :xml, :autocomplete, :index, :show, unless: proc { |_c| (current_user && current_user.is?(:owner, @hub)) || params[:no_cache] == 'true' }, expires_in: Tagteam::Application.config.default_action_cache_time, cache_path: proc {
    if request.fullpath =~ /tag\/rss/
      params[:format] = :rss
    elsif request.fullpath =~ /tag\/atom/
      params[:format] = :atom
    elsif request.fullpath =~ /tag\/json/
      params[:format] = :json
    elsif request.fullpath =~ /tag\/xml/
      params[:format] = :xml
    end
    Digest::MD5.hexdigest(request.fullpath + '&per_page=' + get_per_page)
  }

  protect_from_forgery except: :json

  # Autocomplete ActsAsTaggableOn::Tag results for a Hub as json.
  def autocomplete
    hub_id = @hub.id
    @search = ActsAsTaggableOn::Tag.search do
      with :hub_ids, hub_id
      fulltext params[:term]
    end

    respond_to do |format|
      format.json do
        # Should probably change this to use render_for_api
        render json: @search.results.collect { |r| { id: r.id, label: r.name } }
      end
    end
  rescue
    render plain: 'Please try a different search term', layout: !request.xhr?
  end

  # A paginated list of ActsAsTaggableOn::Tag objects for a Hub. Returns html, json, and xml.
  def index
    @tags = if @hub_feed.blank?
              @hub.tag_counts
            else
              FeedItem.tag_counts_on_items(@hub_feed.feed_items.pluck(:id),
                                           @hub.tagging_key).all
            end

    if @tags.any?
      # tag_sorter = TagSorter.new(:tags => @tags, :sort_by => :created_at, :context => @hub.tagging_key, :class => FeedItem)
      tag_sorter = TagSorter.new(tags: @tags, sort_by: :frequency)
      @tags = tag_sorter.sort
    end

    respond_to do |format|
      format.html { render layout: request.xhr? ? false : 'tabs' }
      format.json { render_for_api :default, json: @tags, root: :tags }
      format.xml { render_for_api :default, xml: @tags, root: :tags }
    end
  end

  # A paginated RSS feed of FeedItem objects for a Hub and a ActsAsTaggableOn::Tag. This doesn't use the normal respond_to / format system because we use names instead of IDs to identify a tag.
  def rss
    Feeds::StoreFeedVisitorJob.perform_later(
      request.path,
      'rss',
      request.remote_ip,
      request.user_agent
    )
   end

  # A paginated Atom feed of FeedItem objects for a Hub and a ActsAsTaggableOn::Tag.
  def atom
    Feeds::StoreFeedVisitor.perform_later(
      request.path,
      'atom',
      request.remote_ip,
      request.user_agent
    )
  end

  # A paginated json list of FeedItem objects for a Hub and a ActsAsTaggableOn::Tag.
  def json
    render_for_api :default,  json: @feed_items
  end

  # A paginated xml list of FeedItem objects for a Hub and a ActsAsTaggableOn::Tag.
  def xml
    render_for_api :default,  xml: @feed_items
  end

  # A paginated html list of FeedItem objects for a Hub and a ActsAsTaggableOn::Tag.
  def show
    @show_auto_discovery_params = hub_tag_rss_url(@hub, @tag.name)
    @feed_items =
      FeedItem
      .tagged_with(@tag.name, on: @hub.tagging_key)
      .uniq
      .order(date_published: :desc, created_at: :desc)
      .paginate(page: params[:page], per_page: get_per_page)
    template = params[:view] == 'grid' ? 'show_grid' : 'show'
    render template, layout: request.xhr? ? false : 'tabs'
  end

  private

  def load_hub
    if params[:hub_feed_id].present?
      @hub_feed = HubFeed.find(params[:hub_feed_id])
      @hub = @hub_feed.hub
    else
      @hub = Hub.find(params[:hub_id])
    end
  end

  def add_breadcrumbs
    breadcrumbs.add @hub.to_s, hub_path(@hub)
    breadcrumbs.add @hub_feed.feed.title, hub_feed_path(@hub_feed) if @hub_feed
  end

  def load_tag_from_name
    @tag = if !params[:name].blank?
             ActsAsTaggableOn::Tag.find_by_name_normalized(params[:name])
           else
             ActsAsTaggableOn::Tag.find_by(id: params[:id])
           end
    unless @tag
      flash[:error] = "We're sorry, but '#{params[:name]}' is not a tag for '#{@hub.title}'"

      redirect_to hub_path(@hub) + '?no_cache=true'
    end
  end

  def load_feed_items_for_rss
    @feed_items = FeedItem.tagged_with(@tag.name, on: @hub.tagging_key)
                          .limit(50).order('date_published DESC, created_at DESC')
  end

  def set_prefixed_tags
    @prefixed_tags = Statistics::HubPrefixedTags.run!(tag_counts: @hub.tag_counts)
  end
end
