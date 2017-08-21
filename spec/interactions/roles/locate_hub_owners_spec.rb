# frozen_string_literal: true

require 'rails_helper'
require 'support/interactions'

module Roles
  RSpec.describe LocateHubOwners do
    include_context 'interactions'

    describe 'the interaction' do
      let(:hub_owner) { create(:user) }
      let(:hub) { create(:hub) }
      let(:inputs) { {} }
      let(:non_hub_owner) { create(:user) }

      before { hub_owner.has_role!(:owner, hub) }

      it 'returns a collection of users with the owner role on any hub' do
        expect(result).to include(hub_owner)
      end

      it 'does not return users who do not have the owner role on any hub' do
        expect(result).not_to include(non_hub_owner)
      end
    end
  end
end
