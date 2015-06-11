class TagFiltersController < ApplicationController
  before_filter :load_scope
  before_filter :load_tag_filter, except: [:index, :new, :create]

  access_control do
    allow all, to: [:index]
    allow :superadmin
    allow :owner, of: :hub
    allow :hub_tag_filterer, to: [:new, :create] if @scope.is_a? Hub
    allow :hub_feed_tag_filterer, to: [:new, :create] if @scope.is_a? HubFeed
    allow :hub_feed_item_tag_filterer, to: [:new, :create] if @scope.is_a? FeedItem
    allow :owner, of: :tag_filter, to: [:destroy]
  end

  def index
    # Need to be careful and use #in_hub here because feed items can exist in
    # multiple hubs. We'll always get a hub variable.
    @tag_filters = @scope.tag_filters.in_hub(@hub)
    #breadcrumbs.add @feed_item.to_s, hub_feed_feed_item_path(@hub_feed,@feed_item)
    respond_to do |format|
      format.html { render template, layout: request.xhr? ? false : 'tabs' }
      format.json { render_for_api :default,  json: @tag_filters }
      format.xml { render_for_api :default,  xml: @tag_filters }
    end
  end

  def new
    @tag_filter = TagFilter.new(hub: @hub, scope: @scope)
  end

  def create
    filter_type = params[:filter_type].constantize
    if params[:modify_tag]
      @tag = find_or_create_tag_by_name(params[:modify_tag])
      @new_tag = find_or_create_tag_by_name(params[:new_tag])
    else
      @tag = find_or_create_tag_by_name(params[:new_tag])
    end
    @tag_filter = filter_type.new(hub: @hub, scope: @hub,
                                  tag: @tag, new_tag: @new_tag)

    if @tag_filter.save
      current_user.has_role!(:owner, @tag_filter)
      current_user.has_role!(:creator, @tag_filter)
      flash[:notice] = 'Added that filter to this hub.'

      TagFilter.delay.apply_by_id(@tag_filter.id)
    else
      flash[:error] = 'Could not add that tag filter.'
    end
  end

  def destroy
    @tag_filter.destroy
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

    # We'll only get a hub feed id if we're scoped to a hub feed.
    if @hub_feed
      @scope = @hub_feed
      @hub = @hub_feed.feed
    # We'll get a hub if we're scoped to a hub or a feed item.
    elsif @hub
      # We'll only get a feed item if we're scoped to a feed item.
      if @feed_item
        @scope = @feed_item
        # We could load a hub feed here, but it could be one of many (if the same
        # item comes in from multiple feeds), so I'd rather not.
      else
        @scope = @hub
      end
    end
  end

  def load_tag_filter
    @tag_filter = TagFilter.find(params[:id])
  end
end
