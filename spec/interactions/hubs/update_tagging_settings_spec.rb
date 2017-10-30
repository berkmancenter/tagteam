# frozen_string_literal: true

require 'rails_helper'
require 'support/interactions'

module Hubs
  RSpec.describe UpdateTaggingSettings do
    include_context 'interactions'
    it_behaves_like 'an interaction'

    let(:hub) { build(:hub) }
    let(:inputs) do
      {
        hub: hub,
        tags_delimiter: ',',
        official_tag_prefix: 'test',
        hub_approved_tags: 'test'
      }
    end
  end
end
