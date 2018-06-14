# frozen_string_literal: true
class TagFilterPolicy < ApplicationPolicy
  def create?
    return false unless user.present?

    user.has_role?(:superadmin) ||
      user.has_role?(:owner, record.hub) ||
      (user.has_role?(:hub_tag_adder, record.hub) && ([AddTagFilter, TagFilter].include?(record.class))) ||
      (user.has_role?(:hub_tag_deleter, record.hub) && record.is_a?(DeleteTagFilter)) ||
      (user.has_role?(:hub_tag_modifier, record.hub) && record.is_a?(ModifyTagFilter)) ||
      user.has_role?(:hub_feed_tag_filterer, record.hub) ||
      user.has_role?(:hub_feed_item_tag_filterer, record.hub)
  end

  def destroy?
    return false unless user.present?

    user.has_role?(:superadmin) ||
      user.has_role?(:owner, record.hub) ||
      user.has_role?(:owner, record) ||
      user.has_role?(:hub_tag_deleter, record.hub)
  end
end
