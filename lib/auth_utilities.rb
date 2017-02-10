# frozen_string_literal: true
module AuthUtilities
  def owners
    find_role('owner')
  end

  def creators
    find_role('creator')
  end

  def editors
    find_role('editor')
  end

  def bookmarkers
    find_role('bookmarker')
  end

  def users_with_roles
    accepted_roles.collect(&:users).flatten.uniq
  end

  def find_role(role_name = 'owner')
    role_list = accepted_roles.reject { |r| r.name != role_name }
    role_list.blank? ? [] : role_list.first.users.compact.uniq
  end
end
