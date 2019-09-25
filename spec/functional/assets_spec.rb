# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Asset compilation' do
  it 'executes without error' do
    expect(system('rake assets:precompile')).to be true
  end
end
