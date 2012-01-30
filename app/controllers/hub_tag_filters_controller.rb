class HubTagFiltersController < ApplicationController
  before_filter :load_hub, :except => [:index, :new, :create]
  before_filter :prep_resources

  def create
    
  end

  def destroy

  end

  def load_hub
    @hub = Hub.find(params[:id])
    @owners = @hub.owners
    @is_owner = @owners.include?(current_user)
  end
end
