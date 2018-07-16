# frozen_string_literal: true
require 'rails_helper'

RSpec.describe RepublishedFeedPolicy do
  subject { described_class.new(user, republished_feed) }

  let(:republished_feed) { create(:republished_feed) }

  context 'for an anonymous user' do
    let(:user) { nil }

    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to forbid_action(:edit) }
    it { is_expected.to permit_action(:inputs) }
    it { is_expected.to permit_action(:items) }
    it { is_expected.to forbid_action(:new) }
    it { is_expected.to permit_action(:removals) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_action(:update) }
  end

  context 'for an owner of the hub' do
    let(:user) { create(:user) }
    let(:hub) { create(:hub) }
    let(:republished_feed) { create(:republished_feed, hub: hub) }

    before { user.has_role!(:owner, hub) }

    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to permit_action(:edit) }
    it { is_expected.to permit_action(:inputs) }
    it { is_expected.to permit_action(:items) }
    it { is_expected.to permit_action(:new) }
    it { is_expected.to permit_action(:removals) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:update) }
  end

  context 'for an owner of the republished feed' do
    let(:user) { create(:user) }

    before { user.has_role!(:owner, republished_feed) }

    it { is_expected.to forbid_action(:create) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to permit_action(:edit) }
    it { is_expected.to permit_action(:inputs) }
    it { is_expected.to permit_action(:items) }
    it { is_expected.to forbid_action(:new) }
    it { is_expected.to permit_action(:removals) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:update) }
  end

  context 'for a remixer of the hub' do
    let(:user) { create(:user) }
    let(:hub) { create(:hub) }
    let(:republished_feed) { create(:republished_feed, hub: hub) }

    before { user.has_role!(:remixer, hub) }

    it { is_expected.to permit_action(:create) }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to forbid_action(:edit) }
    it { is_expected.to permit_action(:inputs) }
    it { is_expected.to permit_action(:items) }
    it { is_expected.to permit_action(:new) }
    it { is_expected.to permit_action(:removals) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_action(:update) }
  end

  context 'for a superadmin' do
    let(:user) { create(:user, :superadmin) }

    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to permit_action(:edit) }
    it { is_expected.to permit_action(:inputs) }
    it { is_expected.to permit_action(:items) }
    it { is_expected.to permit_action(:new) }
    it { is_expected.to permit_action(:removals) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:update) }
  end
end
