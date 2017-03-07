# frozen_string_literal: true
require 'rails_helper'

module Admin
  RSpec.describe UserApprovalsMailer, type: :mailer do
    describe '#notify_admin_of_signup' do
      let(:user) { build(:user) }
      let(:superadmin) { create(:user, :superadmin) }
      let(:mail) { described_class.notify_admin_of_signup(user) }

      before { superadmin }

      it 'sets the recipients' do
        expect(mail.to).to include(superadmin.email)
      end
    end

    describe '#notify_user_of_approval' do
      let(:user) { create(:user) }
      let(:mail) { described_class.notify_user_of_approval(user) }

      it 'sets the recipient' do
        expect(mail.to).to contain_exactly(user.email)
      end
    end

    describe '#notify_user_of_denial' do
      let(:user) { create(:user) }
      let(:mail) { described_class.notify_user_of_denial(user) }

      it 'sets the recipient' do
        expect(mail.to).to contain_exactly(user.email)
      end
    end
  end
end
