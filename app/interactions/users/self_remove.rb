# frozen_string_literal: true
module Users
  # Remove a user
  class SelfRemove < ActiveInteraction::Base
    object :user

    def execute
      if user.nil?
        errors[:base] << 'No user found.'

        return
      end

      # Destroy all user's hubs, but omit these with a solo owner
      user_hubs = user.my
      user_hubs.reject! { |hub| hub.owners.count > 1 }
      user_hubs.each(&:destroy)

      # Destroy the user
      user.destroy
    end
  end
end
