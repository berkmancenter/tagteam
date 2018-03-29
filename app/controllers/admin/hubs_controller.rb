# frozen_string_literal: true

module Admin
  # Homepage for admin features
  class HubsController < ApplicationController
    before_action :authenticate_user!
    after_action :verify_authorized

    SORT_OPTIONS = {
      'title' => ->(rel) { rel.order('title') },
      'created_date' => ->(rel) { rel.order('created_at') },
      'owners' => ->(rel) { rel.by_first_owner },
      'id' => ->(rel) { rel.order(:id) }
    }.freeze

    SORT_DIR_OPTIONS = %w(asc desc).freeze

    def index
      authorize :admin_hub, :index?
      @order =  params[:order] || 'asc'
      @sort =  params[:sort] || 'title'

      sort = SORT_OPTIONS.keys.include?(params[:sort]) ? params[:sort] : SORT_OPTIONS.keys.first
      order = SORT_DIR_OPTIONS.include?(params[:order]) ? params[:order] : SORT_DIR_OPTIONS.first

      @hubs = SORT_OPTIONS[sort].call(policy_scope(Hub)).paginate(page: params[:page], per_page: get_per_page)
      @hubs = @hubs.reverse_order if order == 'desc'
    end

    def destroy
      authorize :admin_hub, :index?
      @hubs = Hub.where(id: params[:hub_ids])

      if @hubs.destroy_all
        flash[:notice] = 'You have successfully destroyed the hub'
      else
        flash[:error] = "Something went wrong, try again."
      end
      
      render :js => "window.location.href = '#{admin_hubs_path}'"
    end
  end
end