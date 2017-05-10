# frozen_string_literal: true
require 'rails_helper'

RSpec.describe RepublishedFeed, type: :model do
  describe 'validations' do
    subject { create(:republished_feed) }

    it { is_expected.to validate_uniqueness_of(:url_key) }
  end
end
