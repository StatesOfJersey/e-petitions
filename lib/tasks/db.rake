namespace :db do
  namespace :migrate do
    desc "Migrate the database, waiting if another server is already migrating it"
    task :wait => :environment do
      attempts = 0

      # Calls the migrations directly rather than invoking db:migrate because
      # AppSignal reports errors raised by a task even when they're rescued
      begin
        ActiveRecord::Tasks::DatabaseTasks.migrate_all
      rescue ActiveRecord::ConcurrentMigrationError
        raise if (attempts += 1) >= 60

        puts "Another server is migrating the database, retrying in 5 seconds"
        Kernel.sleep 5
        retry
      end
    end
  end
end
