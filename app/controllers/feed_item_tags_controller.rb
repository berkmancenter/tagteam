class FeedItemTagsController < ApplicationController
  access_control do
    allow all
  end

  def index
    @feed_item_tags = FeedItemTag.paginate(:order => 'tag', :page => params[:page], :per_page => 500)
  end

  def show
    @feed_item_tag = FeedItemTag.find(params[:id])
    @feed_items = @feed_item_tag.feed_items.paginate(:order => 'date_published desc', :page => params[:page], :per_page => params[:per_page])
  end
end
