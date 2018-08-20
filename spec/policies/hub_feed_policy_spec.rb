# frozen_string_literal: true
require 'rails_helper'

RSpec.describe HubFeedPolicy do
  subject { described_class.new(user, hub_feed) }

  let(:hub_feed) { create(:hub_feed) }

  context 'for an anonymous user' do
    let(:user) { nil }

    it { is_expected.to permit_action(:autocomplete) }
    it { is_expected.to permit_action(:controls) }
    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to forbid_action(:edit) }
    it { is_expected.to forbid_action(:import) }
    it { is_expected.to forbid_action(:import_items) }
    it { is_expected.to forbid_action(:new) }
    it { is_expected.to forbid_action(:reschedule_immediately) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_action(:update) }
  end

  context 'for an authenticated user' do
    let(:user) { create(:user) }

    context 'with the owner role on the hub feed' do
      before { user.has_role!(:owner, hub_feed) }

      it { is_expected.to permit_action(:destroy) }
      it { is_expected.to permit_action(:edit) }
      it { is_expected.to permit_action(:import) }
      it { is_expected.to permit_action(:reschedule_immediately) }
      it { is_expected.to permit_action(:update) }
    end

    context 'with the owner role on the hub' do
      let(:hub) { create(:hub) }
      let(:hub_feed) { create(:hub_feed, hub: hub) }

      before { user.has_role!(:owner, hub) }

      it { is_expected.to permit_action(:create) }
      it { is_expected.to permit_action(:destroy) }
      it { is_expected.to permit_action(:edit) }
      it { is_expected.to permit_action(:import) }
      it { is_expected.to permit_action(:import_items) }
      it { is_expected.to permit_action(:new) }
      it { is_expected.to permit_action(:reschedule_immediately) }
      it { is_expected.to permit_action(:update) }
    end

    context 'with the bookmarker role on the hub' do
      let(:hub) { create(:hub) }
      let(:hub_feed) { create(:hub_feed, hub: hub) }

      before { user.has_role!(:bookmarker, hub) }

      it { is_expected.to permit_action(:create) }
      it { is_expected.to permit_action(:new) }
    end

    context 'with the superadmin role' do
      let(:user) { create(:user, :superadmin) }

      it { is_expected.to permit_action(:create) }
      it { is_expected.to permit_action(:destroy) }
      it { is_expected.to permit_action(:edit) }
      it { is_expected.to permit_action(:import) }
      it { is_expected.to permit_action(:import_items) }
      it { is_expected.to permit_action(:new) }
      it { is_expected.to permit_action(:reschedule_immediately) }
      it { is_expected.to permit_action(:update) }
    end
  end
end
