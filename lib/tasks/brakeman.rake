namespace :brakeman do
  desc "Run brakeman checks and exit with an error code if there are any issues"
  task :check do
    system "brakeman -z --no-pager"
  end
end
