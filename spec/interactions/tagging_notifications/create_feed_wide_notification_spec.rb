# frozen_string_literal: true

require 'rails_helper'
require 'support/interactions'

module TaggingNotifications
  RSpec.describe CreateFeedWideNotification do
    include_context 'interactions'
    let(:current_user) { create(:user) }
    let(:feed_items) { create_pair(:feed_item) }
    let(:hub_feed) { create(:hub_feed) }

    let(:inputs) do
      {
        changes: { tags_added: ['tag1'] },
        current_user: current_user,
        feed_items: feed_items,
        hub_feed: hub_feed
      }
    end

    it_behaves_like 'an interaction'
  end
end
