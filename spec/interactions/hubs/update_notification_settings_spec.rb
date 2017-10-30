# frozen_string_literal: true

require 'rails_helper'
require 'support/interactions'

module Hubs
  RSpec.describe UpdateNotificationSettings do
    include_context 'interactions'
    it_behaves_like 'an interaction'

    let(:hub) { build(:hub) }
    let(:inputs) do
      {
        hub: hub,
        notify_taggers: true
      }
    end
  end
end
