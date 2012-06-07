require 'resque/pool/tasks'

task "resque:setup" => :environment do
  Resque.before_fork = Proc.new { ActiveRecord::Base.establish_connection }
  #    Resque.after_fork do |job|
  #      ActiveRecord::Base.establish_connection
  #    end
end

task "resque:pool:setup" do
  # Delete tasks that might've stacked up and that
  # get run via cron normally.
  Resque.redis.del 'queue:update_feeds'
  Resque.redis.del 'queue:file_cache'

  # close any sockets or files in pool manager
  ActiveRecord::Base.connection.disconnect!

  # and re-open them in the resque worker parent
  Resque::Pool.after_prefork do |job|
    ActiveRecord::Base.establish_connection
  end
end

