# frozen_string_literal: true

module Users
  # Sort a collection of Users by various methods
  class Sort < ActiveInteraction::Base
    array :users
    string :sort_method

    def execute
      case sort_method
      when 'application_roles'
        sort_by_application_roles
      when 'confirmed'
        sort_by_virtual_attribute('confirmed?')
      when 'locked'
        sort_by_virtual_attribute('access_locked?')
      when 'owned_hubs'
        sort_by_owned_hubs
      when 'username'
        users.sort_by { |user| user.username.downcase }
      when 'last_sign_in_at'
        sort_by_virtual_attribute('last_sign_in_at')
      end
    end

    private

    def sort_by_application_roles
      users.sort_by do |user|
        [
          -user.application_roles.count,
          user.application_roles.pluck(:name).join(', '),
          user.username.downcase
        ]
      end
    end

    def sort_by_owned_hubs
      users.sort_by do |user|
        [
          -user.my(Hub).count,
          user.username.downcase
        ]
      end
    end

    def sort_by_virtual_attribute(attribute)
      users.sort_by do |user|
        [
          user.send(attribute) ? 0 : 1,
          user.username.downcase
        ]
      end
    end
  end
end
