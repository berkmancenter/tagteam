require 'rails_helper'

RSpec.describe 'Adding Bookmarklets', js: true do
  let(:hub) { create(:hub) }

  it 'returns successfully when a tagger clicks on "Add to Tagteam"' do
    u = create(:confirmed_user)
    # Should be set by factory, but isn't.
    u.update_attributes(approved: true)
    hub.accepts_role!(:bookmarker, u)
    sign_in u
    visit taggers_hub_path(hub)
    page.switch_to_window(
      page.window_opened_by { find('a.btn', text: /Add to TagTeam/i).click() }
    )
    expect(page).to have_http_status(200)
  end

  it 'returns successfully when an admin clicks on "Add to Tagteam"' do
    u = create(:confirmed_user, :superadmin)
    # Should be set by factory, but isn't.
    u.update_attributes(approved: true)
    sign_in u
    visit taggers_hub_path(hub)
    page.switch_to_window(
      page.window_opened_by { find('a.btn', text: /Add to TagTeam/i).click() }
    )
    expect(page).to have_http_status(200)
  end
end
