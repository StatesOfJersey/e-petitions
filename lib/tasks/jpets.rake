namespace :jpets do
  desc "Add sysadmin user"
  task :add_sysadmin_user => :environment do
    if AdminUser.find_by(email: 'admin@example.com').nil?
       admin = AdminUser.new(:first_name => 'Cool', :last_name => 'Admin', :email => 'admin@example.com')
       admin.role = 'sysadmin'
       admin.password = admin.password_confirmation = 'Letmein1!'
       admin.save!
     end
  end

  desc "Email threshold users with a list of threshold petitions"
  task :threshold_email_reminder => :environment do
    Task.run("jpets:threshold_email_reminder") do
      EmailThresholdReminderJob.perform_later
    end
  end

  desc "Special resend of signature email validation"
  task :special_resend_of_signature_email_validation => :environment do
    EmailReminder.special_resend_of_signature_email_validation
  end

  desc "Email members with a petitions report if site is configured to do so today"
  task :enqueue_petitions_report_if_configured_for_today => :environment do
    if Site.petition_report_due?
      Task.run("jpets:enqueue_petitions_report_if_configured_for_today") do
        EmailPetitionsReportJob.set(wait_until: Site.petition_report_due_at).perform_later
      end
    end
  end

  namespace :whenever do
    desc "Update the Primary Server crontab"
    task :update_crontab_primary => :environment do
      Whenever::CommandLine.execute(
        :update => true,
        :set => "environment=#{RAILS_ENV}",
        :identifier => 'Jpets_primary_server'
      )
    end

    desc "Update the all servers crontab"
    task :update_crontab_all => :environment do
      Whenever::CommandLine.execute(
        :update => true,
        :set => "environment=#{RAILS_ENV}",
        :identifier => 'Jpets_all_servers',
        :file => 'config/schedule_all_servers.rb'
      )
    end
  end

  namespace :jobs do
    desc "Unlock all delayed jobs (to be used after a restart)"
    task :unlock_all => :environment do
      Delayed::Job.update_all("locked_by = NULL, locked_at = NULL")
    end
  end

  namespace :site do
    desc "Enable the website"
    task :enable => :environment do
      Site.instance.update! enabled: true
    end

    desc "Disable the website"
    task :disable => :environment do
      Site.instance.update! enabled: false
    end

    desc "Protect the website"
    task :protect => :environment do
      Site.instance.update! protected: true, username: ENV.fetch('SITE_USERNAME'), password: ENV.fetch('SITE_PASSWORD')
    end

    desc "Unprotect the website"
    task :unprotect => :environment do
      Site.instance.update! protected: false
    end
  end

  namespace :journals do
    task :reset_constituencies => :environment do
      ParishPetitionJournal.reset!
    end
  end
end
