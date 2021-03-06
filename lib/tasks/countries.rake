namespace :jpets do
  namespace :countries do
    desc "Add task to the queue to fetch country list from the register"
    task :fetch => :environment do
      Task.run("jpets:countries:fetch") do
        FetchCountryRegisterJob.perform_later
      end
    end
  end
end
