# frozen_string_literal: true

module Roles
  # Return a collection of users who have the 'owner' role on any hub
  class LocateHubOwners < ActiveInteraction::Base
    def execute
      User.distinct.includes(:roles).where(roles: { name: 'owner', authorizable_type: 'Hub' })
    end
  end
end
