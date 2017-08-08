# frozen_string_literal: true

require 'rails_helper'
require 'support/interactions'

module FeedItems
  RSpec.describe Update do
    include_context 'interactions'
    it_behaves_like 'an interaction'

    let(:feed_item) { create(:feed_item) }
    let(:hub) { create(:hub) }
    let(:user) { create(:user) }

    let(:inputs) do
      {
        feed_item: feed_item,
        description: 'Example Description',
        hub: hub,
        title: 'Example Title',
        url: 'http://www.example.com/',
        user: user
      }
    end
  end
end
