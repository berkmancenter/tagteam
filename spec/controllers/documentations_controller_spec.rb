# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DocumentationsController, type: :controller do
  let(:documentation) { create(:documentation) }
  let(:user) { create(:user) }

  xit 'allows access to documentations#show' do
    get :show, params: { id: documentation.id }
    expect(response).to be_success
  end

  context 'for a user without the owner role' do
    xit 'prevents #edit' do
      get :edit, params: { id: documentation.id }
      expect(response).not_to be_success
    end
  end

  context 'for a user with the owner role' do
    before { user.has_role!(:owner, documentation) }

    xit 'allows #edit' do
      sign_in user
      get :edit, params: { id: documentation.id }
      puts response.status
      expect(response).to be_success
    end
  end
end
