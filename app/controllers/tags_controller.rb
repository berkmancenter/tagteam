# frozen_string_literal: true
class TagsController < ApplicationController
  before_action :load_hub
  before_action :load_tag_from_name, only: [:rss, :atom, :show, :json, :xml, :statistics, :description]
  before_action :load_feed_items_for_rss, only: [:rss, :atom, :json, :xml]
  before_action :load_feed_items, only: :statistics
  before_action :add_breadcrumbs
  before_action :set_prefixed_tags, only: [:index]

  caches_action :rss, :atom, :json, :xml, :autocomplete, :show, :statistics, unless: proc { |_c| (current_user && current_user.is?(:owner, @hub)) || params.has_key?(:username) || params[:no_cache] == 'true' }, expires_in: Tagteam::Application.config.default_action_cache_time, cache_path: proc {
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
    deprecated_tags_names = @hub.deprecated_tags.pluck(:name)

    tags_applied = params.has_key?(:tags_applied) ? params[:tags_applied].split(', ') : []

    if params[:offset].nil?
      limit = 25
    else
      limit = params[:offset].to_i + 25
    end

    if @hub.settings[:suggest_only_approved_tags]
      approved_tags = @hub
                     .hub_approved_tags
                     .where.not(tag: deprecated_tags_names)
                     .pluck(:tag)

      result = ActsAsTaggableOn::Tag
               .left_joins(:taggings)
               .where('name LIKE \'' + params[:term] + '%\'')
               .where(name: approved_tags)
               .group(:id)
               .order('COUNT(taggings.id) DESC')
               .limit(limit)

      count = ActsAsTaggableOn::Tag
              .select('DISTINCT(tags.id)')
              .left_joins(:taggings)
              .where.not(name: deprecated_tags_names)
              .where('name LIKE \'' + params[:term] + '%\'')
              .where(name: approved_tags)
              .count
    else
      tag_ids = Rails.cache.fetch("all-tag-ids-#{@hub.id}", expires_in: 1.hour) do
        FeedItem.joins(:hubs, :taggings).where(hubs: { id: @hub.id }).pluck('taggings.tag_id').uniq
      end
      remove_suggested = RemovedTagSuggestion.where(hub_id: @hub.id).map { |rts| rts.tag.name }

      result = ActsAsTaggableOn::Tag
               .left_joins(:taggings)
               .where.not(name: deprecated_tags_names)
               .where.not(name: remove_suggested)
               .where('name LIKE \'' + params[:term] + '%\'')
               .where(id: tag_ids)
               .group(:id)
               .order('COUNT(taggings.id) DESC')
      count = result.length
    end

    respond_to do |format|
      format.json do
        # Should probably change this to use render_for_api
        results = {
          items: result[0..25].map { |r| { id: r[:id], label: r[:name] } },
          more: count > limit
        }
        render json: results.compact
      end
    end
  # rescue
  #   render plain: 'Please try a different search term', layout: !request.xhr?
  end

  # A paginated list of ActsAsTaggableOn::Tag objects for a Hub. Returns html, json, and xml.
  def index
    @tags = @hub_feed.blank? ? @hub.tag_counts :
      FeedItem.tag_counts_on_items(@hub_feed.feed_items.pluck(:id), @hub.tagging_key).all

    @removed_tag_suggestions = RemovedTagSuggestion.where(hub_id: @hub.id).map(&:tag_id)

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
    Feeds::StoreFeedVisitorJob.perform_later(
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
    sort = params[:sort] == 'Date published' ? 'date_published' : 'created_at'
    order = ['desc', 'asc'].include?(params[:order]) ? params[:order] : 'desc'

    if @hub.deprecated_tags.include?(@tag)
      @feed_items = [].paginate
    else
      feed_item_ids = ActsAsTaggableOn::Tagging.where(tag_id: @tag.id, context: @hub.tagging_key, taggable_type: 'FeedItem').map(&:taggable_id).compact
      @feed_items = FeedItem.where(id: feed_item_ids).order("feed_items.#{sort} #{order}").paginate(page: params[:page], per_page: get_per_page)
    end

    @show_auto_discovery_params = hub_tag_rss_url(@hub, @tag.name)
    @tag_description = HubTagDescription.where(hub_id: @hub.id, tag_id: @tag.id).first
    if @tag_description.nil?
      @tag_filter = TagFilter.where(type: 'ModifyTagFilter', hub_id: @hub.id, new_tag_id: @tag.id, scope_type: 'Hub').first
      if @tag_filter.present?
        @old_tag_description = HubTagDescription.where(hub_id: @hub.id, tag_id: @tag_filter.tag_id).first
      end
    end

    template = params[:view] == 'grid' ? 'show_grid' : 'show'
    render template, layout: request.xhr? ? false : 'tabs'
  end

  def description
    # TODO: Authorize

    hub_tag_desc = HubTagDescription.find_or_initialize_by(tag_id: @tag.id, hub_id: @hub.id)
    hub_tag_desc.update_attributes!(description: params[:description])

    # TODO: Eventually track role here?

    render json: {}
  rescue Exception => e
    render json: {}
  end

  def statistics
    authorize @hub

    @taggings_by_user = Statistics::TaggingsByUser.run!(
      hub: @hub,
      tag: @tag
    )

    @before_deprecated_taggings_by_user = Statistics::TaggingsByUser.run!(
      hub: @hub,
      tag: @tag,
      deprecated: true,
      after: false
    )

    @after_deprecated_taggings_by_user = Statistics::TaggingsByUser.run!(
      hub: @hub,
      tag: @tag,
      deprecated: true,
      after: true
    )

    render layout: request.xhr? ? false : 'tabs'
  end

  def tags_used_not_approved
    authorize @hub

    @tags_used_not_approved = Statistics::TagsUsedNotApproved.run!(
      hub: @hub
    )

    render layout: request.xhr? ? false : 'tabs'
  end

  def tags_approved
    authorize @hub

    @tags_approved = Statistics::TagsApproved.run!(
      hub: @hub
    )

    render layout: request.xhr? ? false : 'tabs'
  end

  def deprecated_tags
    authorize @hub

    @year = params[:year]
    @month = params[:month]

    @deprecated_hub_tags = Statistics::DeprecatedTags.run!(
      hub: @hub,
      month: params[:month],
      year: params[:year]
    )

    render layout: request.xhr? ? false : 'tabs'
  end

  private

  def load_hub
    if params[:hub_feed_id].present?
      @hub_feed = HubFeed.find(params[:hub_feed_id])
      @hub = @hub_feed.hub
    else
      @hub = Hub.find(params[:hub_id])
    end
    if params.has_key?(:username)
      @user = User.find_by(username: params[:username])
      @hub_feed = @hub.hub_feeds.detect { |hf| hf.creators.include?(@user) }
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

      redirect_to items_hub_path(@hub) + '?no_cache=true'
    end
  end

  def load_feed_items_for_rss
    @feed_items = FeedItem.tagged_with(@tag.name, on: @hub.tagging_key)
                          .limit(50).order('date_published DESC, created_at DESC')
  end

  def fetch_feed_items
  end

  def load_feed_items
    @feed_items =
      FeedItem
      .tagged_with(@tag.name, on: @hub.tagging_key)
      .order(date_published: :desc, created_at: :desc)
      .paginate(page: params[:page], per_page: get_per_page)
  end

  def set_prefixed_tags
    @prefixed_tags = Statistics::HubPrefixedTags.run!(hub: @hub)
  end
end
