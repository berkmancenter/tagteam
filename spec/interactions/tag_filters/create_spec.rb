# frozen_string_literal: true
require 'rails_helper'
require 'support/interactions'

module TagFilters
  RSpec.describe Create do
    include_context 'interactions'
    it_behaves_like 'an interaction'

    let(:hub) { create(:hub) }
    let(:inputs) do
      {
        filter_type: 'AddTagFilter',
        hub: hub,
        new_tag_name: 'tag1',
        scope: hub,
        user: create(:user)
      }
    end
  end
end
