# frozen_string_literal: true

module Admin
  # model to add settings
  class Setting < ApplicationRecord
    self.table_name = 'admin_settings'

    serialize :whitelisted_domains, Array
    serialize :blacklisted_domains, Array

    validate :uniqueness_of_domains

    private

    def uniqueness_of_domains
      return unless (whitelisted_domains & blacklisted_domains).any?

      errors.add(:base, 'You can\'t add same domain in whitelisted_domains and blacklisted_domains')
    end
  end
end
