# frozen_string_literal: true
require 'rails_helper'

RSpec.describe FeedItemPolicy do
  subject { described_class.new(user, feed_item) }

  let(:hub) { create(:hub) }
  let(:feed_item) { create(:feed_item) }

  context 'for an anonymous user' do
    let(:user) { nil }

    it { is_expected.to forbid_action(:edit) }
    it { is_expected.to forbid_action(:update) }
  end

  context 'for a logged in user' do
    let(:user) { create(:user) }

    context 'with no roles' do
      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:update) }
    end

    # TODO: Find a better test for specific roles on the associated hub
    context 'with an owner role on the hub' do
      before { allow(user).to receive(:has_role?) { true } }

      it { is_expected.to permit_action(:edit) }
      it { is_expected.to permit_action(:update) }
    end
  end

  context 'for a superadmin' do
    let(:user) { create(:user, :superadmin) }

    it { is_expected.to permit_action(:edit) }
    it { is_expected.to permit_action(:update) }
  end
end
