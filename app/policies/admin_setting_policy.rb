# frozen_string_literal: true

# Policy for accessing the admin settings controller
class AdminSettingPolicy < ApplicationPolicy
  def new?
    user_is_superadmin?
  end

  def create?
    user_is_superadmin?
  end

  def update?
    user_is_superadmin?
  end

  private

  def user_is_superadmin?
    return false if user.blank?

    user.has_role?(:superadmin)
  end
end
