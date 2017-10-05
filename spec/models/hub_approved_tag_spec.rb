# frozen_string_literal: true
require 'rails_helper'

RSpec.describe HubApprovedTag, type: :model do
  it 'belongs to hub' do
    @hub = create(:hub)
    @hub_approved_tag = create(
      :hub_approved_tag,
      hub: @hub
    )

    expect(@hub_approved_tag).to  belong_to(:hub)
  end
end
