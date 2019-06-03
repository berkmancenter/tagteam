#!/bin/bash

cd /app
# capybara-webkit needs it
export PATH="/usr/lib/qt5/bin:$PATH"
bundle install
touch log/sidekiq.log
cp -n docker/database.yml config/database.yml
cp -n config/tagteam.yml.example config/tagteam.yml

bundle exec rake db:migrate
bundle exec rake sunspot:solr:start
bundle exec sidekiq -C config/sidekiq.yml -L log/sidekiq.log -d -e development
bundle exec rails server --binding 0.0.0.0 --port 3000
