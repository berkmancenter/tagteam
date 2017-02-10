# frozen_string_literal: true
# A Hub is the base unit of organization for TagTeam. Please see README_FOR_APP for more details on how everything fits together.
class HubsController < ApplicationController
  caches_action :index, :items, :show, :search, :by_date, :retrievals, :bookmark_collections, :meta, unless: proc { |_c| current_user }, expires_in: Tagteam::Application.config.default_action_cache_time, cache_path: proc {
    Digest::MD5.hexdigest(request.fullpath + '&per_page=' + get_per_page)
  }

  access_control do
    allow all, to: [:index, :list, :items, :show, :search, :by_date, :retrievals, :item_search, :bookmark_collections, :all_items, :contact, :request_rights, :meta, :home, :about]
    allow logged_in, to: [:new, :create, :my, :my_bookmark_collections, :background_activity, :tag_controls]
    allow :owner, of: :hub, to: [:edit, :update, :destroy, :add_feed, :my_bookmark_collections, :custom_republished_feeds, :community, :add_roles, :remove_roles]
    allow :inputter, of: :hub, to: [:add_feed]
    allow :remixer, of: :hub, to: [:custom_republished_feeds]
    allow :superadmin
  end

  before_action :sanitize_params, only: :index
  before_action :find_hub, only: [
    :about,
    :add_feed,
    :add_roles,
    :bookmark_collections,
    :by_date,
    :community,
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
    :remove_roles,
    :retrievals,
    :show,
    :tag_controls,
    :update
  ]

  SORT_OPTIONS = {
    'title' => ->(rel) { rel.order('title') },
    'date' => ->(rel) { rel.order('created_at') },
    'owner' => ->(rel) { rel.by_first_owner }
  }.freeze
  SORT_DIR_OPTIONS = %w(asc desc).freeze

  def about
    add_breadcrumbs
    render layout: 'tabs'
  end

  def created
    add_breadcrumbs
  end

  def meta
    render layout: !request.xhr?
  end

  def list
    @hubs = Hub.paginate(page: params[:p] || 1, per_page: 25).order('title ASC')
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
    add_breadcrumbs
    render layout: request.xhr? ? false : 'tabs'
  end

  def community
    add_breadcrumbs
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

  # A list of feed retrievals for the feeds in this hub, accessible via html, json, and xml.
  def retrievals
    add_breadcrumbs
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
  def bookmark_collections
    add_breadcrumbs
    @bookmark_collections = HubFeed.bookmark_collections.where(hub_id: @hub.id).paginate(page: params[:page], per_page: get_per_page)
    respond_to do |format|
      format.html { render layout: request.xhr? ? false : 'tabs' }
      format.json { render_for_api :default, json: @bookmark_collections }
      format.xml { render_for_api :default, xml: @bookmark_collections }
    end
  end

  # Accessible via html, json, and xml. Pass in the date by appending "/" separated parameters to this action, so: /hubs/1/by_date/2012/03/28. If you put in "00" for the month or day parameter, we'll search for all items form that month or year.
  def by_date
    add_breadcrumbs

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
    add_breadcrumbs
    hub_id = @hub.id

    @search = if request.format.to_s =~ /rss|atom/i
                FeedItem.search(include: [:feeds, :hub_feeds]) do
                  with(:hub_ids, hub_id) unless hub_id.blank?
                  order_by('date_published', :desc)
                  order_by('id', :asc)
                  paginate page: params[:page], per_page: get_per_page
                end
              else
                FeedItem.search(select: FeedItem.columns_for_line_item, include: [:feeds, :hub_feeds]) do
                  with(:hub_ids, hub_id) unless hub_id.blank?
                  order_by('date_published', :desc)
                  order_by('id', :asc)
                  paginate page: params[:page], per_page: get_per_page
                end
              end

    respond_to do |format|
      format.html do
        unless @hub.blank?
          @show_auto_discovery_params = items_hub_url(@hub, format: :rss)
        end
        template = if params[:view] == 'grid'
                     'hubs/items_grid'
                   else
                     'hubs/items'
                   end
        render template, layout: request.xhr? ? false : 'tabs'
      end
      format.rss { render template: 'hubs/items.rss' }
      format.atom { render template: 'hubs/items.atom' }
      format.json { render_for_api :default, json: @search.blank? ? [] : @search.results }
      format.xml { render_for_api :default, xml: @search.blank? ? [] : @search.results }
    end
  end

  def tag_controls
    add_breadcrumbs

    @tag = ActsAsTaggableOn::Tag.find(params[:tag_id])

    @already_filtered_for_hub = @hub.tag_filtered?(@tag)

    if params[:hub_feed_id].to_i != 0
      @hub_feed = HubFeed.find(params[:hub_feed_id])
      @already_filtered_for_hub_feed = @hub_feed.tag_filtered?(@tag)
    end

    if params[:hub_feed_item_id].to_i != 0
      @feed_item = FeedItem.find(params[:hub_feed_item_id], select: FeedItem.columns_for_line_item)
      @already_filtered_for_hub_feed_item = @feed_item.tag_filtered?(@tag)
    end

    respond_to do |format|
      format.html do
        render layout: !request.xhr?
      end
    end
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

  # A list of all republished feeds(aka remixed feeds) that can be added to for the current user.
  def custom_republished_feeds
    add_breadcrumbs
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
    @hubs = Hub.paginate(page: params[:page], per_page: 5).order('title ASC') # get_per_page)
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
    @hubs = SORT_OPTIONS[sort].call(Hub.paginate(page: params[:page], per_page: 5))
    @hubs = @hubs.reverse_order if order == 'desc'
    respond_to do |format|
      format.html { render layout: request.xhr? ? false : 'tabs' }
      format.json { render_for_api :default, json: @hubs }
      format.xml { render_for_api :default, xml: @hubs }
    end
  end

  # Available as html, json, or xml.
  def show
    add_breadcrumbs
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
  end

  # A list of the current users' hubs, used mostly by the bookmarklet.
  def my
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
    add_breadcrumbs
    @bookmark_collections = current_user.my_bookmarking_bookmark_collections_in(@hub)
    respond_to do |format|
      format.json { render_for_api :bookmarklet_choices, json: @bookmark_collections }
      format.xml { render_for_api :bookmarklet_choices, xml: @bookmark_collections }
    end
  end

  def create
    @hub = Hub.new
    @hub.attributes = params[:hub]
    add_breadcrumbs
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

  def edit
    add_breadcrumbs
  end

  def update
    add_breadcrumbs
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
        redirect_to :back
      end
    end
  end

  # Search results are available as html, json, or xml.
  def item_search
    add_breadcrumbs
    breadcrumbs.add 'Search', request.url

    hub_id = @hub.id
    tagging_key = @hub.tagging_key

    @search = FeedItem.search do
      with :hub_ids, hub_id
      paginate page: params[:page], per_page: get_per_page
      order_by(:date_published, :desc)
      unless params[:q].blank?
        fulltext params[:q]
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
    @search = Hub.search do
      paginate page: params[:page], per_page: get_per_page
      fulltext params[:q] unless params[:q].blank?
    end

    respond_to do |format|
      format.html { render layout: request.xhr? ? false : 'tabs' }
      format.json { render json: @search }
    end
  end

  private

  def sanitize_params
    params[:page] = params[:page] =~ /^\d*$/ ? params[:page] : 1
  end

  def add_breadcrumbs
    breadcrumbs.add @hub, hub_path(@hub) if @hub.id
  end

  def find_hub
    @hub = Hub.find(params[:id])
  end
end
