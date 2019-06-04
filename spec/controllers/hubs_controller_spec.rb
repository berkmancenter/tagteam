# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HubsController, type: :controller do
  let(:user) { create(:confirmed_user) }
  let(:hub) { create(:hub, :owned) }

  context 'contact action' do
    it 'available to sign-in user' do
      stub_sign_in user
      get :contact, params: { id: hub.id }

      expect(response).to render_template('contact')
    end

    it 'available to non sign-in user' do
      get :contact, params: { id: hub.id }

      expect(response).to render_template('contact')
    end
  end

  context 'request_rights action' do
    it 'contact to hub by filling captcha' do
      allow_any_instance_of(Recaptcha::Verify).to receive(:verify_recaptcha).and_return(true)

      post :request_rights, params: { id: hub.id, contact: { email: 'tester@endpoint.com', message: 'this is a test message', rights: ['rights'] } }

      expect(response).to be_success
      expect(assigns(:errors)).to be_empty
    end

    it 'contact to hub without filling captcha' do
      allow_any_instance_of(Recaptcha::Verify).to receive(:verify_recaptcha).and_return(false)

      post :request_rights, params: { id: hub.id, contact: { email: 'tester@endpoint.com', message: 'this is a test message', rights: ['rights'] } }

      expect(response.status).to be(406)
      expect(assigns(:errors)).to include('reCAPTCHA verification failed')
    end
  end
end
