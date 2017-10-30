# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HubUserNotification, type: :model do
  it { is_expected.to belong_to(:hub) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:hub) }
  it { is_expected.to validate_presence_of(:user) }
  it { is_expected.to have_db_index(%i[hub_id user_id]) }
end
