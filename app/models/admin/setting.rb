# frozen_string_literal: true

module Admin
  # model to add settings
  class Setting < ApplicationRecord
    self.table_name = 'admin_settings'

    serialize :whitelisted_domains, Array
    serialize :blacklisted_domains, Array
  end
end
