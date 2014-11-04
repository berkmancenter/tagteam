# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# From TagTeam production on amy:
# @reboot /web/amy/rails3.2prod/docs/tagteam-1.5-prod/bin/startup.sh

# */10 * * * * cd /web/amy/rails3.2prod/docs/tagteam-1.5-prod/ && i=`/usr/bin/wget -O - -nv --post-file=config/initializers/tagteam_shared_key.rb http://tagteam.harvard.edu/scheduled_tasks/update_feeds 2>&1` || echo $i
# */10 * * * * cd /web/amy/rails3.2prod/docs/tagteam-1.5-prod/ && i=`/usr/bin/wget -O - -nv --post-file=config/initializers/tagteam_shared_key.rb http://tagteam.harvard.edu/scheduled_tasks/expire_cache 2>&1` || echo $i
# 2 1 * * * /web/amy/rails3.2prod/docs/tagteam-1.5-prod/bin/sync_blogs.sh
# 2 2 * * * /web/amy/rails3.2prod/docs/tagteam-1.5-prod/bin/optimize.sh
# 2 3 * * * /usr/bin/find /web/amy/rails3.2prod/docs/tagteam-1.5-prod/tmp/cache/ -type f -mtime +7 -exec rm {} \;
# 2 5 * * * /usr/bin/find /web/amy/rails3.2prod/docs/tagteam-1.5-prod/tmp/cache/ -type d -depth -exec rmdir --ignore-fail-on-non-empty {} +

job_type :job, "cd :path && :environment_variable=:environment bundle exec script/sidekiq_pusher.rb :task :output"

every 10.minutes do
  job 'ExpireFileCache'
  job 'UpdateFeeds'
end
