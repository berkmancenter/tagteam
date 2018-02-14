# frozen_string_literal: true
# The user-edited Documentation controller. The base docs are created via the db:seed rake task during installation.
#
class DocumentationsController < ApplicationController
  caches_action :index, :show, unless: proc { |_c| current_user && current_user.is?([:superadmin, :documentation_admin]) }, expires_in: Tagteam::Application.config.default_action_cache_time, cache_path: proc {
    Digest::MD5.hexdigest(request.fullpath + '&per_page=' + get_per_page)
  }

  before_action :authenticate_user!, except: [:index, :show]
  before_action :find_documentation, only: [:show, :edit, :update, :destroy]

  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def index
    @documentation = policy_scope(Documentation)
  end

  def show
    render layout: !request.xhr?
  end

  def new
    @documentation = Documentation.new
    authorize @documentation
    render layout: !request.xhr?
  end

  def create
    @documentation = Documentation.new
    authorize @documentation
    @documentation.attributes = params[:documentation]
    respond_to do |format|
      if @documentation.save
        current_user.has_role!(:owner, @documentation)
        current_user.has_role!(:creator, @documentation)
        flash[:notice] = 'Added that bit of documentation.'
        format.html { redirect_to documentation_path(@documentation) }
      else
        flash[:error] = 'Could not add that bit of documentation'
        format.html { render action: :new }
      end
    end
  end

  def edit
    render layout: !request.xhr?
  end

  def update
    @documentation.attributes = params[:documentation]
    respond_to do |format|
      if @documentation.save
        current_user.has_role!(:editor, @documentation)
        flash[:notice] = 'Updated!'
        format.html { redirect_to documentation_path(@documentation) }
      else
        flash[:error] = 'Couldn\'t update!'
        format.html { render action: :new }
      end
    end
  end

  def destroy
    @documentation.destroy
    flash[:notice] = 'Deleted that bit of documentation'
    respond_to do |format|
      format.html do
        redirect_to action: :index
      end
    end
  end

  private

  def find_documentation
    @documentation = Documentation.find(params[:id])
    authorize @documentation
  end
end
