class SplitHubTagFiltererIntoTwo < ActiveRecord::Migration[5.0]
  def change
    Role.where(name: 'hub_tag_filterer').each do |role|
      role.users.each do |user|
        user.has_role!(:hub_tag_adder, role.authorizable)
        user.has_role!(:hub_tag_deleter, role.authorizable)
        user.has_role!(:hub_tag_modifier, role.authorizable)
      end
      role.destroy!
    end
  end
end
