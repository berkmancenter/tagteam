#! /usr/bin/env ruby
# scripts/sidekiq_pusher.rb
# bundle exec scripts/sidekiq_pusher.rb Warehouse::FtpPull

require 'sidekiq'
require 'yaml'

klass = ARGV[0]
queue = ARGV[1]
config_file = File.absolute_path(File.join(__dir__, "../config/tagteam.yml"))
tagteam_config = YAML.load_file(config_file)
Sidekiq.configure_client do |config|
  config.redis = {
    url: tagteam_config['redis_host'],
    namespace: tagteam_config['redis_namespace']
  }
end
Sidekiq::Client.push('class' => klass, 'queue' => queue, 'args' => [])
