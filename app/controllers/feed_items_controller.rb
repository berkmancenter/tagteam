class FeedItemsController < ApplicationController
  before_filter :load_hub_feed
  before_filter :load_feed_item, :except => [:index, :by_date]
  before_filter :add_breadcrumbs, :except => [:index, :by_date, :content]

  access_control do
    allow all
  end

  def content
    respond_to do|format|
      format.html{ render :layout => ! request.xhr?}
    end
  end

  def index
    @feed_items = FeedItem.paginate(:order => 'updated_at desc', :page => params[:page], :per_page => params[:per_page])
  end

  def show
  end

  def by_date
    params[:date] = (params[:date].blank?) ? Time.now.strftime('%Y-%m-%d') : params[:date]
    dates = params[:date].split(/\D/).collect{|d| d.to_i}
    if dates.length > 0
      breadcrumbs.add dates[0], by_date_feed_items_path(:date => dates[0])
    end
    if dates.length > 1
      breadcrumbs.add dates[1], by_date_feed_items_path(:date => "#{dates[0]}-#{dates[1]}")
    end
    if dates.length > 2
      breadcrumbs.add dates[2], by_date_feed_items_path(:date => "#{dates[0]}-#{dates[1]}-#{dates[2]}")
    end

    conditions = [
      'extract(year from date_published) = ?',
      ((dates[1].blank?) ? nil : 'extract(month from date_published) = ?'),
      ((dates[2].blank?) ? nil : 'extract(day from date_published) = ?')
    ].compact

    parameters = [
      dates[0],
      ((dates[1].blank?) ? nil : dates[1]),
      ((dates[2].blank?) ? nil : dates[2])
    ].compact

    @feed_items = FeedItem.paginate(:conditions => [conditions.join(' AND '), parameters].flatten, :order => 'date_published desc', :page => params[:page], :per_page => params[:per_page])
  end

  private

  def load_hub_feed
    @hub_feed = HubFeed.find(params[:hub_feed_id])
    @hub = @hub_feed.hub
  end

  def load_feed_item
    @feed_item = FeedItem.find(params[:id])
  end

  def add_breadcrumbs
    unless @hub_feed.blank?
      breadcrumbs.add @hub.to_s, hub_path(@hub) 
      breadcrumbs.add @hub_feed.to_s, hub_hub_feed_path(@hub,@hub_feed) 
    end
  end

end
