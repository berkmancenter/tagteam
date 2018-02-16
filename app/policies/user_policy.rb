# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def autocomplete?
    user.present?
  end

  def destroy?
    return false if user.blank?

    user.has_role?(:superadmin)
  end

  def index?
    return false if user.blank?

    user.has_role?(:superadmin)
  end

  def resend_confirmation_token?
    return false if user.blank?

    user.has_role?(:superadmin)
  end

  def resend_unlock_token?
    return false if user.blank?

    user.has_role?(:superadmin)
  end

  def lock_user?
    return false if user.blank?

    user.has_role?(:superadmin)
  end

  def superadmin_role?
    return false if user.blank?

    user.has_role?(:superadmin)
  end

  def documentation_admin_role?
    return false if user.blank?

    user.has_role?(:superadmin)
  end

  def roles_on?
    user.present?
  end

  def show?
    return false if user.blank?

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

  class Scope < ApplicationPolicy::Scope
    def resolve
      return User.none if user.blank?
      return User.all if user.has_role?(:superadmin)

      User.where(id: user.id)
    end
  end
end
