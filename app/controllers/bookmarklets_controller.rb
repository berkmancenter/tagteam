class BookmarkletsController < ApplicationController

  before_filter :load_hub, :only => [:add_item]

  access_control do
    allow logged_in, :to => [:add,:confirm]
    allow :owner, :of => :hub, :to => [:add_item]
  end

  layout 'bookmarklet'

  def confirm
    @feed_item = FeedItem.find(params[:feed_item_id])
  end

  def add_item
    @mini_title = 'Add this item to a TagTeam stack'
    @feed_item = FeedItem.find_or_initialize_by_url(params[:feed_item][:url])
    [:hub_id, :stack_id, :title,:description, :date_published, :authors, :contributors, :rights, :last_updated].each do |col|
      unless params[:feed_item][col].blank?
        @feed_item.send(%Q|#{col}=|, params[:feed_item][col])
      end
    end

    @feed_item.tag_list = [@feed_item.tag_list, params[:feed_item][:tag_list].split(/,\s*/).collect{|t| t.downcase[0,255].gsub(/,/,'_')}].flatten.compact.join(',')
    @feed = Feed.find(:first, :conditions => {:id => params[:feed_item][:stack_id], :bookmarking_feed => true})

    if @feed.blank? || ! current_user.is?(:owner, @feed)
      @feed = current_user.get_default_bookmarking_stack_for(@hub.id)
    end

    respond_to do|format|
      if @feed_item.save
        unless @feed.feed_items.include?(@feed_item)
          @feed.feed_items << @feed_item
          @feed.save
        end
        current_user.has_role!(:owner, @feed_item)
        current_user.has_role!(:creator, @feed_item)
        Resque.enqueue(FeedItemTagRenderer, @feed_item.id)
        flash[:notice] = 'Added that feed item.'
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

  def add
    @mini_title = 'Add this item to a TagTeam stack'
    @feed_item = FeedItem.find_or_initialize_by_url((params[:feed_item].blank?) ? nil : params[:feed_item][:url])
    [:hub_id, :stack_id, :title,:description, :tag_list, :date_published, :authors, :contributors, :rights, :last_updated].each do |col|
      unless params[:feed_item][col].blank?
        @feed_item.send(%Q|#{col}=|, params[:feed_item][col])
      end
    end
    if @feed_item.new_record?
      @feed_item.date_published = Date.today
    end
  end

  private

  def load_hub
    @hub = Hub.find(params[:hub_id] || params[:feed_item][:hub_id])
  end

end
