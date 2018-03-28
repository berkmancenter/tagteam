# frozen_string_literal: true

require 'rails_helper'
require 'support/interactions'

module Statistics
  RSpec.describe Scoreboard do
    include_context 'interactions'

    let(:hub) { create(:hub) }
    let(:inputs) do
      {
        hub: hub
      }
    end

    it_behaves_like 'an interaction'
  end
end
