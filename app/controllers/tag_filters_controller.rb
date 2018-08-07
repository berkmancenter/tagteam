# frozen_string_literal: true

class TagFiltersController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :load_scope
  before_action :load_tag_filter, except: %i[index new create]

  after_action :verify_authorized, except: :index

  def index
    # Need to be careful and use #in_hub here because feed items can exist in
    # multiple hubs. We'll always get a hub variable.
    @tag_filters = @scope.tag_filters.in_hub(@hub)
    breadcrumbs.add @hub, hub_path(@hub)
    breadcrumbs.add @hub_feed, hub_hub_feed_path(@hub, @hub_feed) if @hub_feed
    breadcrumbs.add @feed_item, hub_feed_item_path(@hub, @feed_item) if @feed_item
    respond_to do |format|
      format.html { render template, layout: request.xhr? ? false : 'tabs' }
      format.json { render_for_api :default, json: @tag_filters }
      format.xml { render_for_api :default, xml: @tag_filters }
    end
  end

  def new
    @tag_filter = TagFilter.new(hub: @hub, scope: @scope)
    authorize @tag_filter
  end

  def create
    authorize_tag_filter = TagFilter.new(type: params[:filter_type])
    authorize_tag_filter.hub = @hub
    authorize authorize_tag_filter

    # Allow multiple TagFilters to be created from a comma-separated string of tags
    params[:new_tag] = params[:new_tag].split(',').join('.')
    tag_filters = if params[:new_tag].empty?
                    [TagFilters::Create.run(tag_filter_params)]
                  else
                    new_tags = TagFilterHelper.split_tags(params[:new_tag], @hub)
                    new_tags -= @hub.deprecated_tag_names
                    new_tags.map do |tag|
                      TagFilters::Create.run(tag_filter_params.merge(new_tag_name: tag))
                    end
                  end

    tag_filters.all?(&:valid?) ? process_successful_create(tag_filters) : process_failed_create(tag_filters)
  end

  def destroy
    @tag_filter.rollback_and_destroy_async(current_user)

    flash[:notice] = 'Deleting that tag filter.'

    redirect_back fallback_location: hub_tag_filters_path(@hub)
  end

  private

  def template
    case @scope.class.name
    when 'Hub'
      'hub_tag_filters/index'
    when 'HubFeed'
      'hub_feed_tag_filters/index'
    when 'FeedItem'
      'hub_feed_item_tag_filters/index'
    end
  end

  def load_scope
    # This controller gets used in different contexts, so we need to figure out
    # what context we're in and instantiate variables appropriately.
    @hub = Hub.find(params[:hub_id]) if params[:hub_id]
    @hub_feed = HubFeed.find(params[:hub_feed_id]) if params[:hub_feed_id]
    @feed_item = FeedItem.find(params[:feed_item_id]) if params[:feed_item_id]

    if params.has_key?(:username)
      @user = User.find_by(username: params[:username])
      @hub_feed = @hub.hub_feeds.detect { |hf| hf.creators.include?(@user) }
    end

    # We'll only get a feed item id if we're scoped to an item.
    if @feed_item
      # We could load a hub feed here, but it could be one of many (if the same
      # item comes in from multiple feeds), so I'd rather not.
      @scope = @feed_item
    # We'll get a hub feed if we're scoped to a feed item or a hub feed.
    elsif @hub_feed
      @scope = @hub_feed
      @hub = @hub_feed.hub
    else
      # We'll get a hub if we're scoped to a hub or a feed item.
      @scope = @hub
    end
  end

  def load_tag_filter
    @tag_filter = TagFilter.find(params[:id])
    authorize @tag_filter
  end

  def tag_filter_params
    {
      filter_type: params[:filter_type],
      hub: @hub,
      hub_feed: @hub_feed,
      modify_tag_name: params[:modify_tag],
      new_tag_name: params[:new_tag],
      scope: @scope,
      user: current_user,
      tag_id: params[:tag_id]
    }
  end

  def process_successful_create(tag_filters)
    notice = t('tag_filters.added', count: tag_filters.size, scope_title: @scope.title)

    flash[:notice] = notice

    render plain: notice, layout: !request.xhr?
  end

  def process_failed_create
    flash[:error] = t('tag_filters.errors_when_adding', count: tag_filters.size)

    errors = tag_filters.map { |tag_filter| tag_filter.errors.full_messages.join('<br/>') }

    render html: errors.join(' '), status: :not_acceptable, layout: !request.xhr?
  end
end
