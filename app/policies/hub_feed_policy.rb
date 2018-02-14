# frozen_string_literal: true
class HubFeedPolicy < ApplicationPolicy
  def autocomplete?
    true
  end

  def controls?
    true
  end

  def create?
    return false unless user.present?

    user.has_role?(:superadmin) ||
      user.has_role?(:owner, record) ||
      user.has_role?(:owner, record.hub) ||
      user.has_role?(:bookmarker, record.hub)
  end

  def destroy?
    return false unless user.present?

    user.has_role?(:superadmin) ||
      user.has_role?(:owner, record) ||
      user.has_role?(:owner, record.hub)
  end

  def import?
    return false unless user.present?

    user.has_role?(:superadmin) ||
      user.has_role?(:owner, record) ||
      user.has_role?(:owner, record.hub)
  end

  def import_items?
    return false unless user.present?

    user.has_role?(:superadmin) || user.has_role?(:owner, record.hub)
  end

  def more_details?
    true
  end

  def reschedule_immediately?
    return false unless user.present?

    user.has_role?(:superadmin) ||
      user.has_role?(:owner, record) ||
      user.has_role?(:owner, record.hub)
  end

  def show?
    true
  end

  def update?
    return false unless user.present?

    user.has_role?(:superadmin) ||
      user.has_role?(:owner, record) ||
      user.has_role?(:owner, record.hub)
  end
end
