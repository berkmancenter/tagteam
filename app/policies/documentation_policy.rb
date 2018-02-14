# frozen_string_literal: true

class DocumentationPolicy < ApplicationPolicy
  def create?
    user_has_superadmin_or_documentation_admin_role
  end

  def update?
    user_has_superadmin_or_documentation_admin_role
  end

  def destroy?
    user_has_superadmin_or_documentation_admin_role
  end

  private

  def user_has_superadmin_or_documentation_admin_role
    return false if user.blank?

    user.has_role?(:superadmin) || user.has_role?(:documentation_admin)
  end
end
