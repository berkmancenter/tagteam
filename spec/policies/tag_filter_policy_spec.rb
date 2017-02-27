# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TagFilterPolicy do
  subject { described_class.new(user, tag_filter) }

  let(:tag_filter) { create(:tag_filter) }

  context 'for an anonymous user' do
    let(:user) { nil }

    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to forbid_action(:new) }
  end

  context 'for a user with the hub_tag_filterer role on the hub' do
    let(:hub) { create(:hub) }
    let(:tag_filter) { create(:tag_filter, hub: hub) }
    let(:user) { create(:user) }

    before { user.has_role!(:hub_tag_filterer, hub) }

    it { is_expected.to permit_action(:create) }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to permit_action(:new) }
  end

  context 'for a user with the hub_feed_tag_filterer role on the hub' do
    let(:hub) { create(:hub) }
    let(:tag_filter) { create(:tag_filter, hub: hub) }
    let(:user) { create(:user) }

    before { user.has_role!(:hub_feed_tag_filterer, hub) }

    it { is_expected.to permit_action(:create) }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to permit_action(:new) }
  end

  context 'for a user with the hub_feed_item_tag_filterer role on the hub' do
    let(:hub) { create(:hub) }
    let(:tag_filter) { create(:tag_filter, hub: hub) }
    let(:user) { create(:user) }

    before { user.has_role!(:hub_feed_item_tag_filterer, hub) }

    it { is_expected.to permit_action(:create) }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to permit_action(:new) }
  end

  context 'for an owner of the tag filter' do
    let(:user) { create(:user) }

    before { user.has_role!(:owner, tag_filter) }

    it { is_expected.to forbid_action(:create) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to forbid_action(:new) }
  end

  context 'for an owner of the hub' do
    let(:hub) { create(:hub) }
    let(:tag_filter) { create(:tag_filter, hub: hub) }
    let(:user) { create(:user) }

    before { user.has_role!(:owner, hub) }

    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to permit_action(:new) }
  end

  context 'for a superadmin' do
    let(:user) { create(:user, :superadmin) }

    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to permit_action(:new) }
  end
end
