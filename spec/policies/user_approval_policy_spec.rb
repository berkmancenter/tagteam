# frozen_string_literal: true
require 'rails_helper'

RSpec.describe UserApprovalPolicy do
  subject { described_class.new(user, :user_approval) }

  context 'anonymous user' do
    let(:user) { nil }

    it { is_expected.to forbid_action(:approve) }
    it { is_expected.to forbid_action(:deny) }
    it { is_expected.to forbid_action(:index) }
  end

  context 'authenticated user' do
    let(:user) { create(:user) }

    context 'with no roles' do
      it { is_expected.to forbid_action(:approve) }
      it { is_expected.to forbid_action(:deny) }
      it { is_expected.to forbid_action(:index) }
    end

    context 'with the superadmin role' do
      before { user.has_role!(:superadmin) }

      it { is_expected.to permit_action(:approve) }
      it { is_expected.to permit_action(:deny) }
      it { is_expected.to permit_action(:index) }
    end
  end
end
