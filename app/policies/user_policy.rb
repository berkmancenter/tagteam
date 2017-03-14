# frozen_string_literal: true
class UserPolicy < ApplicationPolicy
  def autocomplete?
    user.present?
  end

  def destroy?
    return false unless user.present?

    user.has_role?(:superadmin)
  end

  def index?
    return false unless user.present?

    user.has_role?(:superadmin)
  end

  def resend_confirmation_token?
    return false unless user.present?

    user.has_role?(:superadmin)
  end

  def resend_unlock_token?
    return false unless user.present?

    user.has_role?(:superadmin)
  end

  def roles_on?
    user.present?
  end

  def show?
    return false unless user.present?

    user.has_role?(:superadmin)
  end

  def tags?
    true
  end

  def user_tags?
    true
  end

  def tags_json?
    true
  end

  def tags_rss?
    true
  end

  def tags_atom?
    true
  end
end
