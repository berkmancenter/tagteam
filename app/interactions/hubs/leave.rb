# frozen_string_literal: true
module Hubs
  # Remove a user for a hub
  class Leave < ActiveInteraction::Base
    object :hub
    object :user

    def execute
      if user.is?([:owner], hub)
        number_of_owners = Role.find_by(
          authorizable_type: 'Hub',
          authorizable_id: hub.id,
          name: 'owner'
        ).users.count

        if number_of_owners == 1
          errors[:base] << 'You are the only owner of the hub. Add an additional owner first to remove yourself.'
        else
          remove_user_from_hub(user, hub)
        end
      else
        remove_user_from_hub(user, hub)
      end
    end

    private

    def remove_user_from_hub(user, hub)
      user.has_no_roles_for!(hub)
    end
  end
end
