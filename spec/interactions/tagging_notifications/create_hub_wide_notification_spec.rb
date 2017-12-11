# frozen_string_literal: true

require 'rails_helper'
require 'support/interactions'

module TaggingNotifications
  RSpec.describe CreateHubWideNotification do
    include_context 'interactions'
    it_behaves_like 'an interaction'

    let(:current_user) { create(:user) }
    let(:feed_items) { create_pair(:feed_item) }
    let(:hub) { create(:hub) }

    let(:inputs) do
      {
        changes: { tags_added: ['tag1'] },
        current_user: current_user,
        feed_items: feed_items,
        hub: hub
      }
    end
  end
end
