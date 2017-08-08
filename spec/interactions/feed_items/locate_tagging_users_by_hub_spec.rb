# frozen_string_literal: true

require 'rails_helper'
require 'support/interactions'

module FeedItems
  RSpec.describe LocateTaggingUsersByHub do
    include_context 'interactions'
    it_behaves_like 'an interaction'

    let(:feed_item) { create(:feed_item) }
    let(:hub) { create(:hub) }

    let(:inputs) do
      {
        feed_item: feed_item,
        hub: hub
      }
    end
  end
end
