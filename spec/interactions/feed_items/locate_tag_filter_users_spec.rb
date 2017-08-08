# frozen_string_literal: true

require 'rails_helper'
require 'support/interactions'

module FeedItems
  RSpec.describe LocateTagFilterUsers do
    include_context 'interactions'
    it_behaves_like 'an interaction'

    let(:feed_item) { create(:feed_item) }

    let(:inputs) do
      { feed_item: feed_item }
    end
  end
end
