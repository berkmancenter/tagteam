# frozen_string_literal: true

require 'rails_helper'
require 'support/interactions'

module FeedItems
  RSpec.describe LocateUsersToNotify do
    include_context 'interactions'
    it_behaves_like 'an interaction'

    let(:current_user) { create(:user) }
    let(:feed_item) { create(:feed_item) }
    let(:hub) { create(:hub) }

    let(:inputs) do
      {
        current_user: current_user,
        feed_item: feed_item,
        hub: hub
      }
    end
  end
end
