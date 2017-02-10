# frozen_string_literal: true
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) { FactoryGirl.lint traits: true }
end
