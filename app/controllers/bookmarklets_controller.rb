# frozen_string_literal: true

# A "bookmark" is just a FeedItem that's been manually added to a Bookmark Collection. Currently the only way to add bookmarks is through the bookmarklet available under a Hub's "bookmarks" tab.
class BookmarkletsController < ApplicationController
  before_action :load_hub, only: [:add_item, :remove_item]
  before_action :load_feed, only: [:add_item, :remove_item]

  access_control do
    allow logged_in, to: %i[add confirm]
    allow :owner, of: :hub, to: %i[add_item remove_item]
    allow :bookmarker, of: :hub, to: [:add_item]
    allow :superadmin
    allow :owner, of: :feed, to: [:remove_item]
  end

  layout 'bookmarklet'

  def remove_item
    # Can only be removed from bookmarking feeds.
    @feed_item = FeedItem.find(params[:feed_item_id])
    if @feed.is_bookmarking_feed?
      @feed.feed_items.delete(@feed_item)
      flash[:notice] = %(Removed "#{@feed_item.title}" from that bookmark collection)
    else
      flash[:notice] = %(Could not remove "#{@feed_item.title}" from that bookmark collection)
    end
    redirect_to request.referer
  end

  # The page that appears after a bookmark has been successfully added.
  def confirm
    @feed_item = FeedItem.find(params[:feed_item_id])
  end

  # Save the bookmarklet to the correct hub and bookmark collection.
  def add_item
    @mini_title = 'Add to bookmark collection'
    @feed_item = FeedItem.find_or_initialize_by(url: params[:feed_item][:url])
    columns = %i[hub_id bookmark_collection_id title description authors
                 contributors rights]
    columns.each do |col|
      if params[:feed_item][col].present?
        @feed_item.send(%(#{col}=), params[:feed_item][col])
      end
    end

    if params[:feed_item][:date_published].blank?
      @feed_item.date_published = DateTime.current
    else
      date_published = DateTime.parse(params[:feed_item][:date_published])
      @feed_item.date_published = DateTime.new(
        date_published.year,
        date_published.month,
        date_published.day,
        Time.now.hour,
        Time.now.min
      )
    end

    if params[:feed_item][:last_updated].present?
      last_updated = DateTime.parse(params[:feed_item][:last_updated])
      @feed_item.last_updated = DateTime.new(
        last_updated.year,
        last_updated.month,
        last_updated.day,
        Time.current.hour,
        Time.current.min
      )
    end

    @feed = Feed.where(id: params[:feed_item][:bookmark_collection_id], bookmarking_feed: true).first

    # Only add to a feed that the user can add to.
    if @feed.blank? || !current_user.is?(:owner, @feed)
      @feed = current_user.get_default_bookmarking_bookmark_collection_for(@hub.id)
    end

    respond_to do |format|
      if @feed_item.save
        if @feed.feed_items.nil? || !@feed.feed_items.include?(@feed_item)
          @feed.feed_items << @feed_item
          @feed.save
        end
        current_user.has_role!(:owner, @feed_item)
        current_user.has_role!(:creator, @feed_item)

        TagFilterHelper.split_tags(params[:feed_item][:tag_list], @hub).each do |new_tag|
          new_tag = ActsAsTaggableOn::Tag.normalize_name(new_tag)
          ActsAsTaggableOn::Tagging.create(
            tag: ActsAsTaggableOn::Tag.find_or_create_by_name_normalized(new_tag),
            taggable: @feed_item,
            tagger: current_user,
            context: @hub.tagging_key
          )
        end
        TagFilter.apply_hub_filters(@hub, @feed_item)
        TaggingNotifications::FeedItemNotification.perform_later(@feed_item, nil, @hub, current_user)

        @feed_item.reload.solr_index

        format.html do
          redirect_to bookmarklets_confirm_url(feed_item_id: @feed_item.id)
        end
      else
        format.html do
          render
        end
      end
    end
  end

  # Generate the bookmarklet.
  def add
    if current_user.my_bookmarkable_hubs.empty?
      flash[:notice] = "You don't have any hubs in which to put bookmarks.  Please create one."
      session[:redirect_after] = request.fullpath
      @hub = Hub.new
      render 'hubs/new', layout: 'bookmarklet'
    end

    # Remove saved hub preference if hub no longer exists
    if !cookies[:bookmarklet_hub_choice].nil? && !Hub.exists?(cookies[:bookmarklet_hub_choice])
      cookies.delete(:bookmarklet_hub_choice)
    end

    @mini_title = 'Add to TagTeam'

    url = params[:feed_item].blank? ? nil : params[:feed_item][:url]
    stripped_url = UrlsStripper.remove_trackers_hashs_from_url(url)
    @feed_item = FeedItem.find_or_initialize_by(url: stripped_url)

    %i[hub_id bookmark_collection_id title description tag_list date_published authors contributors rights last_updated].each do |col|
      next if params[:feed_item][col].blank?
      next if col == :title && @feed_item.persisted? # Don't overwrite custom-defined titles for existing records

      @feed_item.send(%(#{col}=), params[:feed_item][col])
    end

    return unless @feed_item.new_record?

    @feed_item.date_published = Time.zone.today
    @feed_item.last_updated = Time.zone.today
  end

  private

  def load_hub
    @hub = Hub.find(params[:hub_id] || params[:feed_item][:hub_id])
  end

  def load_feed
    @feed = params.has_key?(:feed_id) ? Feed.find(params[:feed_id]) : Feed.new
  end
end
