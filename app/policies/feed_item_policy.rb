# frozen_string_literal: true

class FeedItemPolicy < ApplicationPolicy
  def update?
    return false if user.blank?
    return true if user.has_role?(:superadmin)

    # Set authorization based on the user's roles on associated hubs
    record.hubs.any? do |hub|
      user.has_role?(:owner, hub) || user.has_role?(:inputter, hub) || user.has_role?(:bookmarker, hub)
    end
  end
end
