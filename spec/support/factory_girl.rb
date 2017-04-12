# frozen_string_literal: true
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  # @TODO move to a rake task
  config.before(:suite) do
    if Rails.env.test?
      begin
        DatabaseCleaner.start
        FactoryGirl.lint(traits: true)
      ensure
        DatabaseCleaner.clean
      end
    else
      system("bundle exec rake factory_girl:lint RAILS_ENV='test'")
    end
  end
end
