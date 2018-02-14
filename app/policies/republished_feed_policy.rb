# frozen_string_literal: true

class RepublishedFeedPolicy < ApplicationPolicy
  def create?
    return false if user.blank?

    user.has_role?(:superadmin) ||
      user.has_role?(:owner, record.hub) ||
      user.has_role?(:remixer, record.hub)
  end

  def destroy?
    return false if user.blank?

    user.has_role?(:superadmin) ||
      user.has_role?(:owner, record.hub) ||
      user.has_role?(:owner, record)
  end

  def inputs?
    true
  end

  def items?
    true
  end

  def more_details?
    true
  end

  def removals?
    true
  end

  def update?
    return false if user.blank?

    user.has_role?(:superadmin) ||
      user.has_role?(:owner, record.hub) ||
      user.has_role?(:owner, record)
  end
end
