# A "bookmark" is just a FeedItem that's been manually added to a Bookmark Collection. Currently the only way to add bookmarks is through the bookmarklet available under a Hub's "bookmarks" tab.
class BookmarkletsController < ApplicationController

  before_filter :load_hub, :only => [:add_item,:remove_item]
  before_filter :load_feed, :only => [:remove_item]

  access_control do
    allow logged_in, :to => [:add,:confirm]
    allow :owner, :of => :hub, :to => [:add_item, :remove_item]
    allow :owner, :of => :feed, :to => [:remove_item]
    allow :bookmarker, :of => :hub, :to => [:add_item]
    allow :superadmin
  end

  layout 'bookmarklet'

  def remove_item
    # Can only be removed from bookmarking feeds.
    @feed_item = FeedItem.find(params[:feed_item_id])
    if @feed.is_bookmarking_feed?
      @feed.feed_items.delete(@feed_item)
      flash[:notice] = %Q|Removed "#{@feed_item.title}" from that bookmark collection|
      @feed_item.update_filtered_tags
    else
      flash[:notice] = %Q|Could not remove "#{@feed_item.title}" from that bookmark collection|
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
    @feed_item = FeedItem.find_or_initialize_by_url(params[:feed_item][:url])
    [:hub_id, :bookmark_collection_id, :title, :description, :authors, :contributors, :rights].each do |col|
      unless params[:feed_item][col].blank?
        @feed_item.send(%Q|#{col}=|, params[:feed_item][col])
      end
    end

    unless params[:feed_item][:date_published].blank?
      date_published = DateTime.parse(params[:feed_item][:date_published])
      @feed_item.date_published = DateTime.new(date_published.year, date_published.month, date_published.day, Time.now.hour, Time.now.min)
    end

    unless params[:feed_item][:last_updated].blank?
      last_updated = DateTime.parse(params[:feed_item][:last_updated])
      @feed_item.last_updated = DateTime.new(last_updated.year, last_updated.month, last_updated.day, Time.now.hour, Time.now.min)
    end

    # Merge tags.
    @feed_item.tag_list = [@feed_item.tag_list, params[:feed_item][:tag_list].split(/,\s*/).collect{|t| t.downcase[0,255].gsub(/,/,'_')}].flatten.compact.join(',')
    @feed = Feed.find(:first, :conditions => {:id => params[:feed_item][:bookmark_collection_id], :bookmarking_feed => true})

    # Only add to a feed that the user can add to.
    if @feed.blank? || ! current_user.is?(:owner, @feed)
      @feed = current_user.get_default_bookmarking_bookmark_collection_for(@hub.id)
    end

    respond_to do|format|
      if @feed_item.save
        if @feed.feed_items.nil? || ! @feed.feed_items.include?(@feed_item)
          @feed.feed_items << @feed_item
          @feed.save
        end
        current_user.has_role!(:owner, @feed_item)
        current_user.has_role!(:creator, @feed_item)
        
        # Assign ownership of the feed item and tag to the user.
        tags = @feed_item.tag_list.uniq.map {|tag_name| ActsAsTaggableOn::Tag.find_or_create_by_name(tag_name)}
        current_user.tag(@feed_item, :with => tags, :on => "hub_#{@hub.id}")
        
        Sidekiq::Client.enqueue(FeedItemTagRenderer, @feed_item.id)
        format.html {
          redirect_to bookmarklets_confirm_url(:feed_item_id => @feed_item.id) 
        }
      else
        format.html{
          render
        }
      end
    end
  end

  # Generate the bookmarklet.
  def add
    if current_user.my_bookmarkable_hubs.empty?
      flash[:notice] = "You don't have any hubs in which to put bookmarks.  Please create one."
      session[:redirect_after] = request.fullpath
      @hub = Hub.new
      render 'hubs/new', :layout => 'bookmarklet'
    end
    # Remove saved hub preference if hub no longer exists
    if !cookies[:bookmarklet_hub_choice].nil? && !Hub.exists?(cookies[:bookmarklet_hub_choice])
      cookies.delete(:bookmarklet_hub_choice)
    end
    @mini_title = 'Add to TagTeam'
    @feed_item = FeedItem.find_or_initialize_by_url((params[:feed_item].blank?) ? nil : params[:feed_item][:url])
    [:hub_id, :bookmark_collection_id, :title,:description, :tag_list, :date_published, :authors, :contributors, :rights, :last_updated].each do |col|
      unless params[:feed_item][col].blank?
        @feed_item.send(%Q|#{col}=|, params[:feed_item][col])
      end
    end
    if @feed_item.new_record?
      @feed_item.date_published = Date.today
      @feed_item.last_updated = Date.today
    end
  end

  private

  def load_hub
    @hub = Hub.find(params[:hub_id] || params[:feed_item][:hub_id])
  end

  def load_feed
    @feed = Feed.find(params[:feed_id])
  end

end
