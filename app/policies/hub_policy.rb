# frozen_string_literal: true
class HubPolicy < ApplicationPolicy
  def about?
    show?
  end

  def add_feed?
    return false unless user.present?
    return true if user.has_role?(:superadmin)

    user.has_role?(:inputter, record) || user.has_role?(:owner, record)
  end

  def add_roles?
    is_owner_or_admin
  end

  def all_items?
    show?
  end

  def background_activity?
    user.present?
  end

  def bookmark_collections?
    show?
  end

  def by_date?
    show?
  end

  def team?
    is_owner_or_admin
  end

  def contact?
    show?
  end

  def create?
    user.present?
  end

  def custom_republished_feeds?
    return false unless user.present?
    return true if user.has_role?(:superadmin)

    user.has_role?(:remixer, record) || user.has_role?(:owner, record)
  end

  def destroy?
    is_owner_or_admin
  end

  def home?
    index?
  end

  def index?
    true
  end

  def item_search?
    show?
  end

  def items?
    show?
  end

  def list?
    index?
  end

  def meta?
    show?
  end

  def my?
    user.present?
  end

  def my_bookmark_collections?
    user.present?
  end

  def notifications?
    user.present?
  end

  def settings?
    return false unless user.present?

    user.has_role?(:superadmin) || user.has_role?(:owner, record)
  end

  def remove_roles?
    is_owner_or_admin
  end

  def request_rights?
    show?
  end

  def retrievals?
    show?
  end

  def search?
    index?
  end

  def set_notifications?
    is_owner_or_admin
  end

  def set_user_notifications?
    user.present?
  end

  def set_settings?
    is_owner_or_admin
  end

  def tag_controls?
    user.present?
  end

  def update?
    is_owner_or_admin
  end

  def recalc_all_tags?
    return false unless user.present?
    return true if user.has_role?(:superadmin)

    false
  end

  def statistics?
    is_owner_or_admin
  end

  def active_taggers?
    is_owner_or_admin
  end

  def tags_used_not_approved?
    is_owner_or_admin
  end

  private

  def is_owner_or_admin
    return false unless user.present?
    return true if user.has_role?(:superadmin)

    user.has_role?(:owner, record)
  end
end
