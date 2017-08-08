# frozen_string_literal: true

require 'rails_helper'
require 'support/interactions'

module FeedItems
  RSpec.describe CreateChangeNotification do
    include_context 'interactions'
    it_behaves_like 'an interaction'

    let(:current_user) { create(:user) }
    let(:hub) { create(:hub) }
    let(:feed_item) { create(:feed_item) }
    let(:changes) { { description: ['old description', 'new description'] } }

    let(:inputs) do
      {
        current_user: current_user,
        hub: hub,
        feed_item: feed_item,
        changes: changes
      }
    end
  end
end
