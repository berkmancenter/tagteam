# frozen_string_literal: true

require 'rails_helper'
require 'support/interactions'

module HubUserNotifications
  RSpec.describe EnableForAllHubUsers do
    include_context 'interactions'
    it_behaves_like 'an interaction'

    let(:hub) { create(:hub) }
    let(:inputs) { { hub: hub } }
  end
end
