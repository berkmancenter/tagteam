#!/bin/bash

cd /app
# capybara-webkit needs it
export PATH="/usr/lib/qt5/bin:$PATH"
bundle install
touch log/sidekiq.log
cp -n docker/database.yml config/database.yml
cp -n config/tagteam.yml.example config/tagteam.yml

bundle exec rake db:migrate RAILS_ENV=test
bundle exec rake spec
