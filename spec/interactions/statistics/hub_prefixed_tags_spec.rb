# frozen_string_literal: true

require 'rails_helper'
require 'support/interactions'

module Statistics
  RSpec.describe HubPrefixedTags do
    include_context 'interactions'
    it_behaves_like 'an interaction'

    let(:hub) { create(:hub) }
    let(:inputs) do
      {
        hub: hub
      }
    end
  end
end
