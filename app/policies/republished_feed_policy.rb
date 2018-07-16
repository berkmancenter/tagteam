# frozen_string_literal: true
class RepublishedFeedPolicy < ApplicationPolicy
  def create?
    return false if user.blank?
    return true if user.has_role?(:superadmin)
    return false if record.hub.blank?

    user.has_role?(:owner, record.hub) || user.has_role?(:remixer, record.hub)
  end

  def destroy?
    return false if user.blank?
    return true if user.has_role?(:superadmin)
    return true if user.has_role?(:owner, record)

    record.hub.present? && user.has_role?(:owner, record.hub)
  end

  def inputs?
    true
  end

  def items?
    true
  end

  def removals?
    true
  end

  def update?
    return false if user.blank?
    return true if user.has_role?(:superadmin)
    return true if user.has_role?(:owner, record)

    record.hub.present? && user.has_role?(:owner, record.hub)
  end
end
