# frozen_string_literal: true
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'approved attribute set by before_create callback' do
    subject { user.approved }

    let(:user) { create(:user, email: email) }

    context 'for a user with an .edu email address' do
      let(:email) { 'example@example.edu' }

      it { is_expected.to be(true) }
    end

    context 'for a user without an .edu email address' do
      let(:email) { 'example@example.com' }

      it { is_expected.to be(false) }
    end
  end

  describe 'signup_reason validation' do
    subject { user }

    let(:user) { build(:user, email: email, signup_reason: nil) }

    before do
      Admin::Setting.create(whitelisted_domains: ['example.edu'])
    end

    context 'for a user with an .edu email address' do
      let(:email) { 'example@example.edu' }

      it { is_expected.not_to validate_presence_of(:signup_reason) }
    end

    context 'for a user without an .edu email address' do
      let(:email) { 'example@example.com' }

      it { is_expected.to validate_presence_of(:signup_reason) }
    end
  end

  describe '#notifications_for_hub?' do
    subject { user.notifications_for_hub?(hub) }

    let(:user) { create(:user) }
    let(:hub) { create(:hub) }

    context 'when a HubUserNotification exists' do
      before do
        create(:hub_user_notification, user: user, hub: hub, notify_about_modifications: notify_about_modifications)
      end

      context 'when notifications are enabled for the hub' do
        let(:notify_about_modifications) { true }

        it { is_expected.to be(true) }
      end

      context 'when notifications are disabled for the hub' do
        let(:notify_about_modifications) { false }

        it { is_expected.to be(false) }
      end
    end

    context 'when no HubUserNotification exists' do
      it { is_expected.to be(true) }
    end
  end
end
