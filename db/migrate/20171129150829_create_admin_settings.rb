# frozen_string_literal: true

# admin_settings table
class CreateAdminSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :admin_settings do |t|
      t.text :signup_description
      t.string :whitelisted_domains
      t.string :blacklisted_domains
    end
  end
end
