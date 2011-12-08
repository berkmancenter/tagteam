class TagsController < ApplicationController

  access_control do
    allow all
  end

  def index
    @tags = FeedItem.tag_counts_on(:tags)
  end

  def show
    @tag = ActsAsTaggableOn::Tag.find(params[:id])
    @feed_items = FeedItem.tagged_with(@tag.name).paginate(:order => 'date_published desc', :page => params[:page], :per_page => params[:per_page])
    render :layout => ! request.xhr?
  end

end
