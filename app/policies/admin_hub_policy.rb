# frozen_string_literal: true

# Policy for accessing the admin hubs controller
class AdminHubPolicy < Struct.new(:user, :admin_hub)
  def index?
    return false if user.blank?

    user.has_role?(:superadmin)
  end

  def destroy?
    return false if user.blank?

    user.has_role?(:superadmin)
  end

end
