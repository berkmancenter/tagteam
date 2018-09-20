# frozen_string_literal: true
# A Hub is the base unit of organization for TagTeam. Please see README_FOR_APP for more details on how everything fits together.
class HubsController < ApplicationController
  caches_action :index, :items, :show, :search, :by_date, :retrievals, :taggers, :meta, unless: proc { |_c| current_user || params[:no_cache] == 'true' }, expires_in: Tagteam::Application.config.default_action_cache_time, cache_path: proc {
    Digest::MD5.hexdigest(request.fullpath + '&per_page=' + get_per_page)
  }
  caches_action :statistics, expires_in: 6.hours

  before_action :authenticate_user!, except: [
    :about,
    :all_items,
    :taggers,
    :by_date,
    :contact,
    :home,
    :index,
    :item_search,
    :items,
    :list,
    :meta,
    :remove_delimiter,
    :request_rights,
    :retrievals,
    :search,
    :show,
    :scoreboard,
    :leave
  ]

  after_action :verify_authorized, except: [:index, :home, :meta]
  after_action :verify_policy_scoped, only: [:index, :home]

  before_action :sanitize_params, only: :index
  before_action :set_feed, only: :unsubscribe_feed
  before_action :set_hub, only: [
    :about,
    :add_feed,
    :add_roles,
    :taggers,
    :by_date,
    :contact,
    :created,
    :custom_republished_feeds,
    :destroy,
    :edit,
    :item_search,
    :items,
    :my_bookmark_collections,
    :recalc_all_tags,
    :request_rights,
    :remove_delimiter,
    :remove_roles,
    :removed_tag_suggestion,
    :retrievals,
    :show,
    :tag_controls,
    :update,
    :set_notifications,
    :notifications,
    :set_user_notifications,
    :settings,
    :set_settings,
    :team,
    :statistics,
    :active_taggers,
    :approve_tag,
    :unapprove_tag,
    :deprecate_tag,
    :undeprecate_tag,
    :unsubscribe_feed,
    :scoreboard,
    :leave
  ]

  before_action :store_feed_visitor, only: :items
  before_action :add_breadcrumbs, only: %i[
    about
    by_date
    contact
    create
    created
    custom_republished_feeds
    edit
    item_search
    items
    my_bookmark_collections
    notifications
    retrievals
    settings
    show
    statistics
    tag_controls
    taggers
    team
    update
  ]
  before_action :authorize_user, only: :settings

  protect_from_forgery except: :items

  # There is some redundancy here, but these can not be reduced without further work
  # index sorts by title, date, owner
  # taggers sorts by username, date started, most recent tagging, # of items
  # scoreboard sorts by rank, username (name), # of items
  SORT_OPTIONS = {
    'title' => ->(rel) { rel.order('title') },
    'date' => ->(rel) { rel.order('hubs.created_at') },
    'owner' => ->(rel) { rel.by_first_owner },
    # ---
    'username' => ->(rel) { rel.sort_by { |hf| hf.owners.any? ? hf.owners.first.username.downcase : 'ZZZ' } }, ## Force sort at end if missing username
    'date started' => ->(rel) { rel.order('hub_feeds.created_at') },
    'most recent tagging' => ->(rel) { rel.sort_by { |r| r.feed_items.any? ? r.feed_items.first.updated_at : r.feed.updated_at } },
    'number of items' => -> (rel) { rel.sort_by { |hf| hf.feed.feed_items.count } },
    # ---
    'name' => -> (rel) { rel.sort_by {|r| r[:username].downcase } },
    'rank' => -> (rel) { rel.sort_by {|r| r[:rank] } },
    'items' => -> (rel) { rel.sort_by {|r| r[:count] } }
  }.freeze

  SORT_DIR_OPTIONS = %w(asc desc).freeze

  def about
    render layout: 'tabs'
  end

  def created; end

  def meta
    render layout: !request.xhr?
  end

  def list
    authorize Hub
    @hubs = Hub.paginate(page: params[:p] || 1, per_page: get_per_page).order('title ASC')
  end

  def request_rights
    breadcrumbs.add @hub, hub_path(@hub)
    @errors = ''
    if params[:contact][:email].nil? || params[:contact][:email] !~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
      @errors += 'Email address is invalid<br/>'
    end

    @errors += 'Please fill in a message' if params[:contact][:message].blank?

    if @errors.blank?
      Contact.request_rights(params, @hub).deliver
      render(plain: '') && return
    else
      render(plain: @errors, status: :not_acceptable) && return
    end
  end

  def contact
    render layout: request.xhr? ? false : 'tabs'
  end

  def team
    @allowed_to_tag = @hub.users_with_roles.size

    render layout: request.xhr? ? false : 'tabs'
  end

  def statistics
    authorize @hub

    @tags = @hub.tags

    @taggers = Statistics::HubTaggers.run!(hub: @hub)

    @prefixed_tags = Statistics::HubPrefixedTags.run!(hub: @hub)

    @hub_wide_filters = @hub.all_tag_filters.where(scope_type: 'Hub')

    @items_with_empty_description = @hub.feed_items.where(description: '')

    @tags_that_use_prefix = Statistics::HubTagsThatUsePrefix.run!(hub: @hub)
    @tags_that_have_no_prefix = Statistics::HubTagsThatHaveNoPrefix.run!(hub: @hub)

    @tags_used_not_approved = Statistics::TagsUsedNotApproved.run!(
      hub: @hub,
      limit: 10
    )

    @altered_items = Statistics::AlteredItems.run!(hub: @hub)

    render layout: request.xhr? ? false : 'tabs'
  end

  def active_taggers
    @taggers = Statistics::HubTaggers.run!(
      hub: @hub,
      month: params[:month],
      year: params[:year]
    )

    render json: @taggers
  end

  def notifications
    @notifications_setup = HubUserNotification.find_or_initialize_by(hub: @hub, user: current_user)

    render layout: request.xhr? ? false : 'tabs'
  end

  def settings
    @settings = @hub.settings

    respond_to do |format|
      format.html { render layout: request.xhr? ? false : 'tabs' }
      format.json { render json: @settings }
    end
  end

  def scoreboard
    @sort = %w[rank name items].include?(params[:sort]) ? params[:sort] : 'rank'
    @order =  params[:order] || 'asc'

    @taggers = Statistics::Scoreboard.run!(hub: @hub,
      sort: @sort,
      criteria: params[:criteria] || 'Year'
    )

    @taggers = SORT_OPTIONS[@sort].call(@taggers)
    @taggers = @taggers.reverse if @order == 'desc'

    @taggers = @taggers.paginate(page: params[:taggers_page], per_page: get_per_page)

    @tags = Statistics::Scoreboard.run!(hub: @hub,
      sort: @sort,
      criteria: params[:criteria] || 'Year',
      type: 'tags'
    )

    @tags = SORT_OPTIONS[@sort].call(@tags)
    @tags = @tags.reverse if @order == 'desc'

    @tags = @tags.paginate(page: params[:tags_page], per_page: get_per_page)

    render layout: request.xhr? ? false : 'tabs'
  end

  def add_roles
    if !params[:user_ids].blank? && !params[:roles].blank?
      params[:user_ids].each do |u|
        user = User.find(u)
        params[:roles].each do |r|
          @hub.accepts_role!(r, user)
        end
      end
    end
    redirect_to request.referer
  end

  def remove_roles
    # TODO: - Refactor this to work in a model-level after trigger, so that rights are properly revoked/reassigned when modified anywhere.
    messages = []
    params[:roles_to_remove] && params[:roles_to_remove].each do |r|
      data = r.split(':')
      user = User.find(data[1])
      next if @hub.accepted_roles_by(user).reject { |q| q.name != data[0] }.empty?
      objects_of_concern = Hub::DELEGATABLE_ROLES_HASH[data[0].to_sym][:objects_of_concern].call(user, @hub)
      if params[:revocation_action] == 'reassign'
        potential_user_to_reassign_to = User.find(params[:reassign_to])
        # could be exploited via URL tampering, so double-check.
        user_to_reassign_to = @hub.owners.include?(potential_user_to_reassign_to) ? potential_user_to_reassign_to : @hub.owners.first
        objects_of_concern.each do |obj|
          obj.accepts_no_role!(:owner, user)
          obj.accepts_role!(:owner, user_to_reassign_to)
        end
      else
        objects_of_concern.each(&:destroy)
      end
      @hub.accepts_no_role!(data[0], user)
      messages << "We deleted #{user.email}'s role as a #{Hub::DELEGATABLE_ROLES_HASH[data[0].to_sym][:name]} in this hub."
    end
    flash[:notice] = messages.join(' ')
    redirect_to request.referer
  end

  def set_notifications
    inputs = { hub: @hub }.reverse_merge(params)

    outcome = Hubs::UpdateNotificationSettings.run(inputs)

    if outcome.valid?
      flash[:notice] = 'Saved successfully.'
    else
      flash[:error] = 'Something went wrong, try again.'
    end

    redirect_to request.referer
  end

  def set_user_notifications
    return if @hub.notifications_mandatory?

    hub_user_notification = HubUserNotification.find_or_initialize_by(hub: @hub, user: current_user)

    if hub_user_notification.update(notify_about_modifications: params[:notify_about_modifications])
      flash[:notice] = 'Saved successfully.'
    else
      flash[:error] = 'Something went wrong, try again.'
    end

    redirect_to request.referer
  end

  def set_settings
    inputs = { hub: @hub }.reverse_merge(params)

    params[:tags_delimiter].gsub!(/\s/, '⎵')
    outcome = Hubs::UpdateTaggingSettings.run(inputs)

    if outcome.valid?
      flash[:notice] = 'Saved successfully.'
    else
      if outcome.errors.keys.include?(:tags_delimiter)
        flash[:error] = outcome.errors.messages[:tags_delimiter].join('<br>')
      else
        flash[:error] = 'Something went wrong, try again.'
      end
    end

    redirect_to request.referer
  end

  # A list of feed retrievals for the feeds in this hub, accessible via html, json, and xml.
  def retrievals
    hub_id = @hub.id
    @feed_retrievals = FeedRetrieval.search(include: [feed: { hub_feeds: [:feed] }]) do
      with(:hub_ids, hub_id)
      order_by('updated_at', :desc)
      paginate page: params[:page], per_page: get_per_page
    end

    respond_to do |format|
      format.html { render layout: request.xhr? ? false : 'tabs' }
      format.json { render_for_api :default, json: @feed_retrievals.blank? ? [] : @feed_retrievals.results }
      format.xml { render_for_api :default, xml: @feed_retrievals.blank? ? [] : @feed_retrievals.results }
    end
  end

  # Looks through the currently running resque jobs and returns a json response talking about what's going on.
  def background_activity
    authorize Hub
    require 'sidekiq/api'
    @output = { running: [] }
    workers = Sidekiq::Workers.new
    workers.collect.each do |_process_id, _thread_id, work|
      started_at = Time.at(work['run_at'])
      running_seconds = Time.now - started_at
      running_for = if running_seconds > 60
                      "#{(running_seconds.round / 60)} minute(s), #{(running_seconds.round % 60)} seconds"
                    else
                      "#{running_seconds.round} seconds"
                    end
      job = {
        description: work['payload']['class'].constantize.display_name,
        since: started_at,
        running_for: running_for
      }
      @output[:running] << job
    end
    stats = Sidekiq::Stats.new
    @output[:queued] = stats.enqueued

    respond_to do |format|
      format.json { render json: @output }
    end
  end

  # A users' bookmark collections, only accessible to logged in users. Accessible as html, json, and xml.
  def taggers
    sort = SORT_OPTIONS.keys.include?(params[:sort]) ? params[:sort] : 'username'
    order = SORT_DIR_OPTIONS.include?(params[:order]) ? params[:order] : SORT_DIR_OPTIONS.first

    @bookmark_collections = SORT_OPTIONS[sort].call(HubFeed.bookmark_collections.by_hub(@hub.id).includes(:hub, :feed))
    @bookmark_collections = @bookmark_collections.reverse if order == 'desc'

    @bookmark_collections = @bookmark_collections.paginate(page: params[:page], per_page: get_per_page)
    respond_to do |format|
      format.html { render layout: request.xhr? ? false : 'tabs' }
      format.json { render_for_api :default, json: @bookmark_collections }
      format.xml { render_for_api :default, xml: @bookmark_collections }
    end
  end

  # Accessible via html, json, and xml. Pass in the date by appending "/" separated parameters to this action, so: /hubs/1/by_date/2012/03/28. If you put in "00" for the month or day parameter, we'll search for all items form that month or year.
  def by_date
    if params[:month] == '00'
      # Year search
      date = DateTime.parse("#{params[:year]}-01-01")
      start_day = date - 1.second
      end_day = date + 1.year
      breadcrumbs.add date.year, by_date_hub_path(@hub, year: date.year, month: '00', day: '00')
    elsif params[:day] == '00'
      # Month search
      date = DateTime.parse("#{params[:year]}-#{params[:month]}-01")
      start_day = date - 1.second
      end_day = date + 1.month
      breadcrumbs.add date.year, by_date_hub_path(@hub, year: date.year, month: '00', day: '00')
      breadcrumbs.add date.month, by_date_hub_path(@hub, year: date.year, month: date.month, day: '00')
    else
      # Day search
      date = DateTime.parse("#{params[:year]}-#{params[:month]}-#{params[:day]}")
      start_day = date - 1.second
      end_day = date + 1.day
      breadcrumbs.add date.year, by_date_hub_path(@hub, year: date.year, month: '00', day: '00')
      breadcrumbs.add date.month, by_date_hub_path(@hub, year: date.year, month: date.month, day: '00')
      breadcrumbs.add date.day, by_date_hub_path(@hub, year: date.year, month: date.month, day: date.day)
    end
    start_day -= DateTime.now.offset
    end_day -= DateTime.now.offset

    hub_id = @hub.id

    @search = FeedItem.search do
      with(:date_published).between(start_day..end_day)
      with :hub_ids, hub_id
      paginate page: params[:page], per_page: get_per_page
      order_by(:date_published, :desc)
    end

    @feed_items = @search.results
    respond_to do |format|
      format.html { render layout: request.xhr? ? false : 'tabs' }
      format.json { render_for_api :default, json: @feed_items }
      format.xml { render_for_api :default, xml: @feed_items }
    end
  end

  # Recalculate all tag facets and re-apply all filters for all items in this hub. Only available to users with the "superadmin" privilege.
  def recalc_all_tags
    Sidekiq::Client.enqueue(RecalcAllItems, @hub.id)
    flash[:notice] = 'Re-rendering all tags. This will take a while.'
    redirect_to request.referer
  end

  def all_items
    items
  end

  # A paginated list of all items in this hub. Available as html, atom, rss, json, and xml.
  def items
    sort = params[:sort] == 'Date published' ? 'date_published' : 'created_at'
    order = ['desc', 'asc'].include?(params[:order]) ? params[:order] : 'desc'
    @feed_items =
      @hub
      .feed_items
      .order("feed_items.#{sort} #{order}")
      .group(:id)
      .paginate(page: params[:page], per_page: get_per_page)

    respond_to do |format|
      format.html do
        @show_auto_discovery_params = items_hub_url(@hub, format: :rss) if @hub.present?

        template = params[:view] == 'grid' ? 'hubs/items_grid' : 'hubs/items'

        render template, layout: request.xhr? ? false : 'tabs'
      end

      format.rss { render template: 'hubs/items.rss' }
      format.atom { render template: 'hubs/items.atom' }
      format.json { render_for_api :default, json: @feed_items.presence || [] }
      format.xml { render_for_api :default, xml: @feed_items.presence || [] }
    end
  end

  def tag_controls
    @tag = ActsAsTaggableOn::Tag.find(params[:tag_id])

    @already_filtered_for_hub = @hub.tag_filtered?(@tag)

    if params[:hub_feed_id].to_i != 0
      @hub_feed = HubFeed.find(params[:hub_feed_id])
      @already_filtered_for_hub_feed = @hub_feed.tag_filtered?(@tag)
    end

    if params[:hub_feed_item_id].to_i != 0
      @feed_item = FeedItem.select(FeedItem.columns_for_line_item).find(params[:hub_feed_item_id])
      @already_filtered_for_hub_feed_item = @feed_item.tag_filtered?(@tag)
    end

    @tagged_by_taggers = Statistics::TagTaggedByTaggers.run!(
      tag: @tag,
      hub: @hub
    ).count
    @tagged_by_filters = Statistics::TagTaggedByFilters.run!(
      tag: @tag,
      hub: @hub
    ).count

    @deprecated = Tags::CheckDeprecated.run!(
      tag: @tag,
      hub: @hub
    )

    @approved = Tags::CheckApproved.run!(
      tag: @tag,
      hub: @hub
    )

    respond_to do |format|
      format.html do
        render layout: !request.xhr?
      end
    end
  end

  def removed_tag_suggestion
    authorize @hub

    if params[:remove] == 'true'
      removed_tag_suggestions = ActsAsTaggableOn::Tag.where(id: params[:tag_id]).map do |tag|
        RemovedTagSuggestion.create(tag: tag, hub_id: @hub.id, user_id: current_user.id)
      end
    else
      RemovedTagSuggestion.where(tag_id: params[:tag_id], hub_id: @hub.id).destroy_all
    end

    render json: {}
  end

  def add_feed
    @feed = Feed.find_or_initialize_by(feed_url: params[:feed_url])

    if @feed.new_record?
      if @feed.save
        current_user.has_role!(:owner, @feed)
        current_user.has_role!(:creator, @feed)
      else
        # Not valid.
        respond_to do |format|
          # Tell 'em why.
          format.json { render(plain: @feed.errors.full_messages.join('<br/>'), status: :not_acceptable) && return }
          format.html do
            flash[:error] = 'There was a problem adding that feed.'
            redirect_to(hub_hub_feeds_path(@hub)) && return
          end
        end
      end
    end

    @hub_feed = HubFeed.new
    @hub_feed.hub = @hub
    @hub_feed.feed = @feed

    if @hub_feed.save
      current_user.has_role!(:owner, @hub_feed)
      current_user.has_role!(:creator, @hub_feed)
      if request.xhr?
        render plain: 'Added that feed', layout: false
      else
        flash[:notice] = 'Added that feed.'
        redirect_to hub_hub_feeds_path(@hub)
      end
    else
      if request.xhr?
        render(html: @hub_feed.errors.full_messages.join('<br />'), status: :not_acceptable)
      else
        flash[:error] = 'There was a problem adding that feed.'
        redirect_to hub_hub_feeds_path(@hub)
      end
    end
  end

  def unsubscribe_feed
    @feed.unsubscribe = true

    if @feed.save
      flash[:notice] = 'You have unsubscribed from the feed'
      redirect_to(hub_hub_feeds_path(@hub))
    else
      flash[:error] = "Something went wrong, try again."
      redirect_to(hub_hub_feeds_path(@hub))
    end
  end

  # A list of all republished feeds(aka remixed feeds) that can be added to for the current user.
  def custom_republished_feeds
    @republished_feeds = RepublishedFeed.select('DISTINCT republished_feeds.*').joins(accepted_roles: [:users]).where(['roles.name = ? and roles.authorizable_type = ? and roles_users.user_id = ? and hub_id = ?', 'owner', 'RepublishedFeed', (current_user.blank? ? nil : current_user.id), @hub.id]).order('updated_at')

    respond_to do |format|
      format.html do
        if request.xhr?
          render layout: false
        else
          render
        end
      end
    end
  end

  def home
    @my_hubs = current_user.my(Hub) if user_signed_in?
    @hubs = policy_scope(Hub).paginate(page: params[:page], per_page: 5).order('title ASC') # get_per_page)
    respond_to do |format|
      format.html { render layout: !request.xhr? }
      format.json { render_for_api :default, json: @hubs }
      format.xml { render_for_api :default, xml: @hubs }
    end
  end

  # All hubs, as html, json, or xml.
  def index
    breadcrumbs.add 'All hubs', hubs_path
    sort = SORT_OPTIONS.keys.include?(params[:sort]) ? params[:sort] : SORT_OPTIONS.keys.first
    order = SORT_DIR_OPTIONS.include?(params[:order]) ? params[:order] : SORT_DIR_OPTIONS.first
    @hubs = SORT_OPTIONS[sort].call(policy_scope(Hub).paginate(page: params[:page], per_page: 5))
    @hubs = @hubs.reverse_order if order == 'desc'
    respond_to do |format|
      format.html { render layout: request.xhr? ? false : 'tabs' }
      format.json { render_for_api :default, json: @hubs }
      format.xml { render_for_api :default, xml: @hubs }
    end
  end

  # Available as html, json, or xml.
  def show
    @show_auto_discovery_params = items_hub_url(@hub, format: :rss)
    redirect_to items_hub_path(@hub)

    # respond_to do|format|
    #  format.html{ render :layout => ! request.xhr? }
    #  format.json{ render_for_api :default, :json => @hub }
    #  format.xml{ render_for_api :default, :xml => @hub }
    # end
  end

  def new
    @hub = Hub.new
    authorize @hub
  end

  # A list of the current users' hubs, used mostly by the bookmarklet.
  def my
    authorize Hub
    @hubs = current_user.my(Hub)
    breadcrumbs.add 'My hubs', my_hubs_path
    respond_to do |format|
      format.html do
        sort = SORT_OPTIONS.keys.include?(params[:sort]) ? params[:sort] : SORT_OPTIONS.keys.first
        order = SORT_DIR_OPTIONS.include?(params[:order]) ? params[:order] : SORT_DIR_OPTIONS.first
        @hubs = SORT_OPTIONS[sort].call(Hub.where(id: @hubs.map(&:id)).paginate(page: params[:page], per_page: 5))
        @hubs = @hubs.reverse_order if order == 'desc'
        render layout: request.xhr? ? false : 'tabs'
      end
      format.json { render_for_api :default, json: @hubs }
      format.xml { render_for_api :default, xml: @hubs }
    end
  end

  # A list of the current users' bookmark collections for a specific hub, used mostly by the bookmarklet.
  def my_bookmark_collections
    @bookmark_collections = current_user.my_bookmarking_bookmark_collections_in(@hub)
    respond_to do |format|
      format.json { render_for_api :bookmarklet_choices, json: @bookmark_collections }
      format.xml { render_for_api :bookmarklet_choices, xml: @bookmark_collections }
    end
  end

  def create
    @hub = Hub.new
    authorize @hub
    @hub.attributes = params[:hub]
    respond_to do |format|
      if @hub.save
        current_user.has_role!(:owner, @hub)
        current_user.has_role!(:creator, @hub)
        format.html do
          if session[:redirect_after].nil?
            redirect_to hub_path(@hub)
          else
            flash[:notice] = 'Added that Hub.'
            redirect_path = session[:redirect_after]
            session[:redirect_after] = nil
            redirect_to redirect_path
          end
        end
      else
        flash[:error] = 'Could not add that Hub'
        format.html { render action: :new }
      end
    end
  end

  def edit; end

  def update
    @hub.attributes = params[:hub]
    respond_to do |format|
      if @hub.save
        current_user.has_role!(:editor, @hub)
        flash[:notice] = 'Updated!'
        format.html { redirect_to hub_path(@hub) }
      else
        flash[:error] = 'Couldn\'t update!'
        format.html { render action: :new }
      end
    end
  end

  def destroy
    @hub.destroy
    flash[:notice] = 'Deleted that hub'
    respond_to do |format|
      format.html do
        redirect_to my_hubs_path
      end
    end
  end

  # Search results are available as html, json, or xml.
  def item_search
    breadcrumbs.add 'Search', request.url

    hub_id = @hub.id
    tagging_key = @hub.tagging_key

    sort = params[:sort] == 'Date published' ? 'date_published' : 'created_at'
    order = ['desc', 'asc'].include?(params[:order]) ? params[:order] : 'desc'
    @modify_tag_filters = params[:q].gsub(/^#/, '').split(/\s/).delete_if { |b| !b.present? }.map do |tag_name|
      ModifyTagFilter.find_recursive(@hub.id, tag_name)
    end.compact
    @filtered_params = params[:q].dup
    @modify_tag_filters.each { |mf| @filtered_params.gsub!(/#{mf.tag.name}/, mf.new_tag.name) }

    date_params = [
      {
        param: :last_updated,
        param_from: :last_updated_from,
        param_to: :last_updated_to,
      },
      {
        param: :date_published,
        param_from: :date_published_from,
        param_to: :date_published_to,
      }
    ]

    @search = FeedItem.search do
      with :hub_ids, hub_id
      date_params.each do |date_param|
        if !params[date_param[:param_from]].present? && params[date_param[:param_to]].present?
          with(date_param[:param]).less_than Date.strptime(params[date_param[:param_to]], '%m/%d/%Y').to_date
        end
        if params[date_param[:param_from]].present? && !params[date_param[:param_to]].present?
          with(date_param[:param]).greater_than Date.strptime(params[date_param[:param_from]], '%m/%d/%Y').to_date
        end
        if params[date_param[:param_from]].present? && params[date_param[:param_to]].present?
          with(date_param[:param]).between Date.strptime(params[date_param[:param_from]], '%m/%d/%Y').to_date..Date.strptime(params[date_param[:param_to]], '%m/%d/%Y').to_date
        end
      end
      paginate page: params[:page], per_page: get_per_page
      order_by(sort.to_sym, order.to_sym)
      unless params[:q].blank?
        fulltext params[:q].split('+').join('+ ')
        adjust_solr_params do |params|
          params[:q].gsub! '#', "tag_contexts_sm:#{tagging_key}-"
        end
      end
    end

    unless params[:q].blank?
      params[:q].gsub! "tag_contexts_sm:#{@hub.tagging_key}-", '#'
    end

    respond_to do |format|
      format.html { render layout: request.xhr? ? false : 'tabs' }
      format.json { render_for_api :default, json: @search.blank? ? [] : @search.results }
      format.xml { render_for_api :default, xml: @search.blank? ? [] : @search.results }
    end
  end

  def search
    authorize Hub

    @search = Hub.search do
      paginate page: params[:page], per_page: get_per_page
      fulltext params[:q].split('+').join('+ ') unless params[:q].blank?
    end

    respond_to do |format|
      format.html { render layout: request.xhr? ? false : 'tabs' }
      format.json { render json: @search }
    end
  end

  def approve_tag
    tag = ActsAsTaggableOn::Tag.find(params[:tag_id])

    approved = HubApprovedTag.new(
      tag: tag,
      hub_id: @hub.id
    )

    @hub.hub_approved_tags << approved

    if @hub.save
      if request.xhr?
        render(html: 'Successfully approved.', layout: false)
      else
        flash[:notice] = 'Successfully approved.'
        redirect_to hub_tags_path(@hub)
      end
    elsif
      if request.xhr?
        render(html: 'There was a problem approving that tag.', status: :not_acceptable)
      else
        flash[:error] = 'There was a problem approving that tag.'
        redirect_to hub_tags_path(@hub)
      end
    end
  end

  def unapprove_tag
    tag = ActsAsTaggableOn::Tag.find(params[:tag_id])

    to_unapproved = HubApprovedTag.where(
      tag: tag.name,
      hub_id: @hub.id
    ).first

    if to_unapproved.destroy
      if request.xhr?
        render(html: 'Successfully unapproved.', layout: false)
      else
        flash[:notice] = 'Successfully unapproved.'
        redirect_to hub_tags_path(@hub)
      end
    elsif
      if request.xhr?
        render(html: 'There was a problem unapproving that tag.', status: :not_acceptable)
      else
        flash[:error] = 'There was a problem unapproving that tag.'
        redirect_to hub_tags_path(@hub)
      end
    end
  end

  def deprecate_tag
    tag = ActsAsTaggableOn::Tag.find(params[:tag_id])

    add_filter = TagFilter.where(
      tag_id: tag.id,
      type: 'AddTagFilter',
      hub_id: @hub.id,
      scope_type: 'Hub',
      scope_id: @hub.id
    ).first

    deprecation_filter = TagFilters::Create.run(
      tag_id: tag.id,
      filter_type: 'DeleteTagFilter',
      hub: @hub,
      scope: @hub,
      new_tag_name: '',
      user: current_user
    )

    if (add_filter.nil? || add_filter.rollback_and_destroy(current_user)) && deprecation_filter.valid?
      if request.xhr?
        render(html: 'Successfully deprecated.', layout: false)
      else
        flash[:notice] = 'Successfully deprecated.'
        redirect_to hub_tags_path(@hub)
      end
    elsif
      if request.xhr?
        render(html: 'There was a problem deprecating that tag.', status: :not_acceptable)
      else
        flash[:error] = 'There was a problem deprecating that tag.'
        redirect_to hub_tags_path(@hub)
      end
    end
  end

  def undeprecate_tag
    tag = ActsAsTaggableOn::Tag.find(params[:tag_id])
    removed_params = {
      tag_id: tag.id,
      type: 'DeleteTagFilter',
      hub_id: @hub.id,
      scope_type: 'Hub',
      scope_id: @hub.id
    }
    replaced_params = {
      tag_id: tag.id,
      type: 'ModifyTagFilter',
      hub_id: @hub.id,
      scope_type: 'Hub',
      scope_id: @hub.id
    }

    removed_filters = TagFilter.where(removed_params)
    replaced_filters = TagFilter.where(replaced_params)

    removed_filters.map { |filter| filter.rollback_and_destroy(current_user) }
    replaced_filters.map { |filter| filter.rollback_and_destroy(current_user) }

    if request.xhr?
      render(html: 'Successfully undeprecated.', layout: false)
    else
      flash[:notice] = 'Successfully undeprecated.'
      redirect_to hub_tags_path(@hub)
    end
  end

  def remove_delimiter
    authorize @hub

    if @hub.tags_delimiter.include?(params[:delimiter])
      flash[:notice] = 'Delimiter removed successfully'
      @hub.tags_delimiter.delete(params[:delimiter]) if params[:delimiter] != ','
      @hub.save
    else
      flash[:error] = 'Something went wrong, try again.'
    end

    redirect_to settings_hub_path(@hub)
  end

  def leave
    authorize @hub

    outcome = Hubs::Leave.run(hub: @hub, user: current_user)

    if outcome.valid?
      flash[:notice] = 'You have been removed from the hub.'
    else
      flash[:error] = outcome.errors.full_messages.join(' and ')
    end

    redirect_to request.referer
  end

  private

  def sanitize_params
    params[:page] = params[:page] =~ /^\d*$/ ? params[:page] : 1
  end

  def add_breadcrumbs
    breadcrumbs.add @hub, hub_path(@hub) if @hub&.id
  end

  def set_hub
    @hub = Hub.find(params[:id])
    authorize @hub
  end

  def set_feed
    @feed = Feed.find(params[:feed_id])

    if @feed.blank?
      flash[:error] = 'Something went wrong, try again.'
      redirect_to(hub_path(@hub))
    end
  end

  def set_feed_items
  end

  def store_feed_visitor
    Feeds::StoreFeedVisitorJob.perform_later(
      request.path,
      request.format.symbol.to_s,
      request.remote_ip,
      request.user_agent
    )
  end

  def authorize_user
    return if policy(@hub).settings?

    raise Pundit::NotAuthorizedError, "You can't access that - sorry!"
  end
end
