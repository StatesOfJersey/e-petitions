class AdminMailer < ActionMailer::Base
  default from: ->(email){ Site.email_from }

  def threshold_email_reminder(admin_users, petitions)
    @petitions = petitions
    mail(subject: "Petitions alert", to: admin_users.map(&:email))
  end

  def petitions_report(now = Time.current.beginning_of_day)
    since = now - 1.week

    @petitions = Petition.open_or_signed_within(since, now)

    subject = "Petitions report #{since.strftime("%d %b %Y")} - #{now.strftime("%d %b %Y")}"

    mail(subject: subject, to: Site.petition_report_email)
  end
end
