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

env :PATH, ENV['PATH']

every :day, at: '12.00am' do
  rake "jpets:enqueue_petitions_report_if_configured_for_today"
end

every :day, at: '2.30am' do
  rake "jpets:petitions:count", output: nil
end

every :day, at: '3.30am' do
  rake "jpets:postcodes:refresh", output: nil
end

every :day, at: '7.00am' do
  rake "jpets:petitions:close", output: nil
end

every :day, at: '7.15am' do
  rake "jpets:petitions:debated", output: nil
end

every :day, at: '7.30am' do
  rake "jpets:petitions:anonymize", output: nil
end
