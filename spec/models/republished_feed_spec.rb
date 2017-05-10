# frozen_string_literal: true
require 'rails_helper'

RSpec.describe RepublishedFeed, type: :model do
  describe 'validations' do
    subject { create(:republished_feed) }

    it { is_expected.to validate_uniqueness_of(:url_key) }
    it { is_expected.to allow_value('foo').for(:url_key) }
    it { is_expected.not_to allow_value('@_@').for(:url_key) }
  end
end
