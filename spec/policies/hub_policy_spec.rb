# frozen_string_literal: true
require 'rails_helper'

RSpec.describe HubPolicy do
  subject { described_class.new(user, hub) }

  let(:hub) { create(:hub) }

  context 'for an anonymous user' do
    let(:user) { nil }

    it { is_expected.to permit_action(:about) }
    it { is_expected.to forbid_action(:add_feed) }
    it { is_expected.to forbid_action(:add_roles) }
    it { is_expected.to permit_action(:all_items) }
    it { is_expected.to forbid_action(:background_activity) }
    it { is_expected.to permit_action(:taggers) }
    it { is_expected.to permit_action(:by_date) }
    it { is_expected.to permit_action(:contact) }
    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:custom_republished_feeds) }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to forbid_action(:edit) }
    it { is_expected.to permit_action(:home) }
    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:item_search) }
    it { is_expected.to permit_action(:items) }
    it { is_expected.to permit_action(:list) }
    it { is_expected.to permit_action(:meta) }
    it { is_expected.to forbid_action(:my) }
    it { is_expected.to forbid_action(:my_bookmark_collections) }
    it { is_expected.to forbid_action(:new) }
    it { is_expected.to forbid_action(:notifications) }
    it { is_expected.to forbid_action(:remove_roles) }
    it { is_expected.to permit_action(:request_rights) }
    it { is_expected.to permit_action(:retrievals) }
    it { is_expected.to permit_action(:search) }
    it { is_expected.to forbid_action(:set_notifications) }
    it { is_expected.to forbid_action(:set_user_notifications) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_action(:tag_controls) }
    it { is_expected.to forbid_action(:team) }
    it { is_expected.to forbid_action(:update) }
    it { is_expected.to forbid_action(:statistics) }
    it { is_expected.to forbid_action(:active_taggers) }
    it { is_expected.to forbid_action(:tags_used_not_approved) }
    it { is_expected.to forbid_action(:leave) }
  end

  context 'for a logged in user' do
    let(:user) { create(:user) }

    it { is_expected.to permit_action(:about) }
    it { is_expected.to permit_action(:all_items) }
    it { is_expected.to permit_action(:background_activity) }
    it { is_expected.to permit_action(:taggers) }
    it { is_expected.to permit_action(:by_date) }
    it { is_expected.to permit_action(:contact) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:home) }
    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:item_search) }
    it { is_expected.to permit_action(:items) }
    it { is_expected.to permit_action(:list) }
    it { is_expected.to permit_action(:meta) }
    it { is_expected.to permit_action(:my) }
    it { is_expected.to permit_action(:my_bookmark_collections) }
    it { is_expected.to permit_action(:new) }
    it { is_expected.to permit_action(:notifications) }
    it { is_expected.to permit_action(:request_rights) }
    it { is_expected.to permit_action(:retrievals) }
    it { is_expected.to permit_action(:search) }
    it { is_expected.to permit_action(:set_user_notifications) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:tag_controls) }
    it { is_expected.to forbid_action(:statistics) }
    it { is_expected.to forbid_action(:active_taggers) }
    it { is_expected.to forbid_action(:tags_used_not_approved) }

    context 'with an owner role on the hub' do
      before { user.has_role!(:owner, hub) }

      it { is_expected.to permit_action(:add_feed) }
      it { is_expected.to permit_action(:add_roles) }
      it { is_expected.to permit_action(:custom_republished_feeds) }
      it { is_expected.to permit_action(:destroy) }
      it { is_expected.to permit_action(:edit) }
      it { is_expected.to permit_action(:remove_roles) }
      it { is_expected.to permit_action(:set_notifications) }
      it { is_expected.to permit_action(:team) }
      it { is_expected.to permit_action(:update) }
      it { is_expected.to permit_action(:statistics) }
      it { is_expected.to permit_action(:active_taggers) }
      it { is_expected.to permit_action(:tags_used_not_approved) }
      it { is_expected.to permit_action(:leave) }
    end

    context 'with an inputter role on the hub' do
      before { user.has_role!(:inputter, hub) }

      it { is_expected.to permit_action(:add_feed) }
      it { is_expected.to forbid_action(:add_roles) }
      it { is_expected.to forbid_action(:custom_republished_feeds) }
      it { is_expected.to forbid_action(:destroy) }
      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:remove_roles) }
      it { is_expected.to forbid_action(:team) }
      it { is_expected.to forbid_action(:update) }
      it { is_expected.to permit_action(:leave) }
    end

    context 'with a remixer role on the hub' do
      before { user.has_role!(:remixer, hub) }

      it { is_expected.to forbid_action(:add_feed) }
      it { is_expected.to forbid_action(:add_roles) }
      it { is_expected.to permit_action(:custom_republished_feeds) }
      it { is_expected.to forbid_action(:destroy) }
      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:remove_roles) }
      it { is_expected.to forbid_action(:team) }
      it { is_expected.to forbid_action(:update) }
      it { is_expected.to permit_action(:leave) }
    end

    context "for a hub they don't have a role on" do
      it { is_expected.to forbid_action(:add_feed) }
      it { is_expected.to forbid_action(:add_roles) }
      it { is_expected.to forbid_action(:custom_republished_feeds) }
      it { is_expected.to forbid_action(:destroy) }
      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:remove_roles) }
      it { is_expected.to forbid_action(:set_notifications) }
      it { is_expected.to forbid_action(:team) }
      it { is_expected.to forbid_action(:update) }
      it { is_expected.to forbid_action(:leave) }
    end
  end

  context 'for a superadmin' do
    let(:user) { create(:user, :superadmin) }

    it { is_expected.to permit_action(:about) }
    it { is_expected.to permit_action(:add_feed) }
    it { is_expected.to permit_action(:add_roles) }
    it { is_expected.to permit_action(:all_items) }
    it { is_expected.to permit_action(:background_activity) }
    it { is_expected.to permit_action(:taggers) }
    it { is_expected.to permit_action(:by_date) }
    it { is_expected.to permit_action(:contact) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:custom_republished_feeds) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to permit_action(:edit) }
    it { is_expected.to permit_action(:home) }
    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:item_search) }
    it { is_expected.to permit_action(:items) }
    it { is_expected.to permit_action(:list) }
    it { is_expected.to permit_action(:meta) }
    it { is_expected.to permit_action(:my) }
    it { is_expected.to permit_action(:my_bookmark_collections) }
    it { is_expected.to permit_action(:new) }
    it { is_expected.to permit_action(:notifications) }
    it { is_expected.to permit_action(:remove_roles) }
    it { is_expected.to permit_action(:request_rights) }
    it { is_expected.to permit_action(:retrievals) }
    it { is_expected.to permit_action(:search) }
    it { is_expected.to permit_action(:set_notifications) }
    it { is_expected.to permit_action(:set_user_notifications) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:tag_controls) }
    it { is_expected.to permit_action(:team) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:statistics) }
    it { is_expected.to permit_action(:active_taggers) }
    it { is_expected.to permit_action(:tags_used_not_approved) }
    it { is_expected.to forbid_action(:leave) }
  end
end
