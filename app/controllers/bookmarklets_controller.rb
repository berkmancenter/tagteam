class BookmarkletsController < ApplicationController

  before_filter :load_hub, :only => [:add_item]

  access_control do
    allow logged_in, :to => [:add]
    allow :owner, :of => :hub, :to => [:add_item]
  end

  layout 'bookmarklet'

  def add_item
    @feed_item = FeedItem.new
    [:hub_id, :stack_id, :url,:title,:description, :tag_list, :date_published, :authors, :contributors, :rights, :last_updated].each do |col|
      unless params[:feed_item][col].blank?
        @feed_item.send(%Q|#{col}=|, params[:feed_item][col])
      end
    end

    @feed_item.tag_ids = params[:tag_ids]
    @feed = Feed.find(:first, :conditions => {:id => params[:feed_item][:stack_id], :bookmarking_feed => true})

    if @feed.blank? || ! current_user.is?(:owner, @feed)
      @feed = current_user.get_default_bookmarking_stack_for(@hub.id)
    end
    
  end

  def add
    @feed_item = FeedItem.new
    [:hub_id, :stack_id, :url,:title,:description, :tag_list, :date_published, :authors, :contributors, :rights, :last_updated].each do |col|
      unless params[:feed_item][col].blank?
        @feed_item.send(%Q|#{col}=|, params[:feed_item][col])
      end
    end
  end

  private

  def load_hub
    @hub = Hub.find(params[:hub_id] || params[:feed_item][:hub_id])
  end

end
