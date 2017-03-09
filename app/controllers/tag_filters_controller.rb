# frozen_string_literal: true
class TagFiltersController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :load_scope
  before_action :load_tag_filter, except: [:index, :new, :create]

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
    filter_type = params[:filter_type].constantize
    unless params[:tag_id].blank?
      @tag = ActsAsTaggableOn::Tag.find(params[:tag_id])
    end

    if params[:filter_type] == 'ModifyTagFilter'
      @tag ||= find_or_create_tag_by_name(params[:modify_tag])
      @new_tag = find_or_create_tag_by_name(params[:new_tag])
    else
      @tag ||= find_or_create_tag_by_name(params[:new_tag])
    end

    @tag_filter = filter_type.new
    @tag_filter.hub = @hub
    @tag_filter.scope = @scope
    @tag_filter.tag = @tag
    @tag_filter.new_tag = @new_tag if @new_tag

    authorize @tag_filter

    if @tag_filter.save
      current_user.has_role!(:owner, @tag_filter)
      current_user.has_role!(:creator, @tag_filter)
      flash[:notice] = %(Added a filter for that tag to "#{@scope.title}")

      if @hub.notify_taggers && @new_tag
        hub_feed_to_notify = @hub_feed.nil? ? nil : @hub_feed.id

        Sidekiq::Client.enqueue(
          SendTagChangeNotifications,
          @tag_filter.id,
          @tag.id,
          @new_tag.id,
          @scope.class.name,
          @scope.id,
          @hub.id,
          hub_feed_to_notify,
          current_user.id
        )
      end

      if @hub.allow_taggers_to_sign_up_for_notifications
        @tag_filter.notify_about_items_modification(@hub, current_user)
      end

      @tag_filter.apply_async

      render plain: %(Added a filter for that tag to "#{@scope.title}"),
             layout: !request.xhr?
    else
      flash[:error] = 'Could not add that tag filter.'
      render html: @tag_filter.errors.full_messages.join('<br/>'),
             status: :not_acceptable,
             layout: !request.xhr?
    end
  end

  def destroy
    if @hub.allow_taggers_to_sign_up_for_notifications
      @tag_filter.notify_about_items_modification(@hub, current_user)
    end
    @tag_filter.rollback_and_destroy_async

    flash[:notice] = 'Deleting that tag filter.'
    redirect_to hub_tag_filters_path(@hub)
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
end
