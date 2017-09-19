# frozen_string_literal: true

# Policy for accessing the admin home controller
class AdminHomePolicy < Struct.new(:user, :admin_home)
  def index?
    return false if user.blank?

    user.has_role?(:superadmin)
  end
end
