# frozen_string_literal: true
require 'rails_helper'

RSpec.describe DocumentationPolicy do
  subject { described_class.new(user, documentation) }

  let(:documentation) { create(:documentation) }

  context 'anonymous user' do
    let(:user) { nil }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to forbid_action(:update) }
  end

  context 'user with no roles' do
    let(:user) { create(:user) }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to forbid_action(:update) }
  end

  context 'superadmin' do
    let(:user) { create(:user, :superadmin) }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to permit_action(:update) }
  end

  context 'documentation_admin' do
    let(:user) { create(:user, :documentation_admin) }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to permit_action(:update) }
  end
end
