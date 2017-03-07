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

    context 'for a user with an .edu email address' do
      let(:email) { 'example@example.edu' }

      it { is_expected.not_to validate_presence_of(:signup_reason) }
    end

    context 'for a user without an .edu email address' do
      let(:email) { 'example@example.com' }

      it { is_expected.to validate_presence_of(:signup_reason) }
    end
  end
end
