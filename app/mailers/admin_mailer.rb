class AdminMailer < ActionMailer::Base
  default from: ->(email){ Site.email_from }

  def threshold_email_reminder(admin_users, petitions)
    @petitions = petitions
    mail(subject: "Petitions alert", to: admin_users.map(&:email))
  end

  def petitions_report(today = Time.current.beginning_of_day)
    last_week = today - 1.week

    @petitions = Petition.open_or_signed_since(last_week)

    subject = "Petitions report #{last_week.strftime("%d %b %Y")} - #{today.strftime("%d %b %Y")}"

    mail(subject: subject, to: Site.petition_report_email)
  end
end
