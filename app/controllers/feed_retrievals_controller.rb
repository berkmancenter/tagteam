class FeedRetrievalsController < ApplicationController

  def show
    @feed_retrieval = FeedRetrieval.find(params[:id])
  end

end
