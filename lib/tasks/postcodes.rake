namespace :jpets do
  namespace :postcodes do
    desc "Add a task to warmup the postcode cache"
    task :warmup => :environment do
      Task.run("jpets:postcodes:warmup") do
        WarmupPostcodesJob.perform_later
      end
    end

    desc "Add a task to refresh the postcode cache"
    task :refresh => :environment do
      Task.run("jpets:postcodes:refresh") do
        RefreshPostcodesJob.perform_later
      end
    end

    desc "Clear the postcode cache"
    task :clear => :environment do
      Postcode.delete_all
    end
  end
end
