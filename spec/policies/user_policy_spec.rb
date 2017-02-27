# frozen_string_literal: true
require 'rails_helper'

RSpec.describe UserPolicy do
  subject { described_class.new(user, user_resource) }

  let(:user_resource) { create(:user) }

  context 'anonymous user' do
    let(:user) { nil }

    it { is_expected.to forbid_action(:autocomplete) }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to forbid_action(:index) }
    it { is_expected.to forbid_action(:resend_confirmation_token) }
    it { is_expected.to forbid_action(:resend_unlock_token) }
    it { is_expected.to forbid_action(:roles_on) }
    it { is_expected.to forbid_action(:show) }
    it { is_expected.to permit_action(:tags) }
    it { is_expected.to permit_action(:user_tags) }
  end

  context 'user with no roles' do
    let(:user) { create(:user) }

    it { is_expected.to permit_action(:autocomplete) }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to forbid_action(:index) }
    it { is_expected.to forbid_action(:resend_confirmation_token) }
    it { is_expected.to forbid_action(:resend_unlock_token) }
    it { is_expected.to permit_action(:roles_on) }
    it { is_expected.to forbid_action(:show) }
    it { is_expected.to permit_action(:tags) }
    it { is_expected.to permit_action(:user_tags) }
  end

  context 'superadmin' do
    let(:user) { create(:user, :superadmin) }

    it { is_expected.to permit_action(:autocomplete) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:resend_confirmation_token) }
    it { is_expected.to permit_action(:resend_unlock_token) }
    it { is_expected.to permit_action(:roles_on) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:tags) }
    it { is_expected.to permit_action(:user_tags) }
  end
end
