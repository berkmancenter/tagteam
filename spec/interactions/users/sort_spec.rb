# frozen_string_literal: true

require 'rails_helper'
require 'support/interactions'

module Users
  RSpec.describe Sort do
    include_context 'interactions'

    let(:alpha) { create(:user, username: 'alpha') }
    let(:bravo) { create(:user, username: 'bravo') }
    let(:charlie) { create(:user, username: 'charlie') }
    let(:sort_method) { 'username' }
    let(:users) do
      charlie
      bravo
      alpha
      User.last(3)
    end

    let(:inputs) do
      {
        users: users,
        sort_method: sort_method
      }
    end

    it_behaves_like 'an interaction'

    describe 'the result' do
      subject { result }

      context 'when sorting by application roles' do
        let(:sort_method) { 'application roles' }

        before { bravo.has_role!(:superadmin) }

        it { is_expected.to eq([bravo, alpha, charlie]) }
      end

      context 'when sorting by confirmation status' do
        let(:sort_method) { 'confirmed' }

        before { bravo.update!(confirmed_at: nil) }

        it { is_expected.to eq([alpha, charlie, bravo]) }
      end

      context 'when sorting by locked status' do
        let(:sort_method) { 'locked' }

        before { charlie.lock_access! }

        it { is_expected.to eq([charlie, alpha, bravo]) }
      end

      context 'when sorting by owned hubs' do
        let(:hub) { build(:hub) }
        let(:sort_method) { 'owned hubs' }

        before { charlie.has_role!(:owner, hub) }

        it { is_expected.to eq([charlie, alpha, bravo]) }
      end

      context 'when sorting by username' do
        let(:sort_method) { 'username' }

        it { is_expected.to eq([alpha, bravo, charlie]) }
      end
    end
  end
end
