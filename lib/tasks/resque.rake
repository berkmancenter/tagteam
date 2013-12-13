# require 'resque/pool/tasks'
# 
# task "resque:setup" => :environment do
#   Resque.before_fork = Proc.new { ActiveRecord::Base.establish_connection }
#   #    Resque.after_fork do |job|
#   #      ActiveRecord::Base.establish_connection
#   #    end
# end
# 
# task "resque:pool:setup" do
#   # Delete tasks that might've stacked up and that
#   # get run via cron normally.
# 
#   # close any sockets or files in pool manager
#   ActiveRecord::Base.connection.disconnect!
# 
#   # and re-open them in the resque worker parent
#   Resque::Pool.after_prefork do |job|
#     ActiveRecord::Base.establish_connection
#   end
# end


require 'resque/pool/tasks'
require 'resque_scheduler/tasks'
# this task will get called before resque:pool:setup
# and preload the rails environment in the pool manager
task "resque:setup" => :environment do
    # generic worker setup, e.g. Hoptoad for failed jobs
    require 'resque_scheduler'
    require 'resque/scheduler'

    resque_schedule = 'config/resque_schedule.yml'
    Resque.schedule = YAML.load_file(resque_schedule) if File.exist?(resque_schedule)
end
task "resque:pool:setup" do
    # close any sockets or files in pool manager
    ActiveRecord::Base.connection.disconnect!
    # and re-open them in the resque worker parent
    Resque::Pool.after_prefork do |job|
        ActiveRecord::Base.establish_connection
    end
end
