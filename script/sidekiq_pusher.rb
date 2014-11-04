#! /usr/bin/env ruby
# scripts/sidekiq_pusher.rb
# bundle exec scripts/sidekiq_pusher.rb Warehouse::FtpPull

require 'sidekiq'
require 'yaml'

klass = ARGV[0]
config_file = File.absolute_path(File.join(__dir__, "../config/tagteam.yml"))
tagteam_config = YAML.load_file(config_file)
Sidekiq.configure_client do |config|
  config.redis = {
    namespace: tagteam_config.redis_namespace,
    url: tagteam_config.redis_host
  }
end
Sidekiq::Client.push('class' => klass, 'args' => [])
