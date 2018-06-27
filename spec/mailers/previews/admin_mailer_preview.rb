# Preview all emails at http://localhost:3000/rails/mailers/admin_mailer
class AdminMailerPreview < ActionMailer::Preview
  def petitions_report
    AdminMailer.petitions_report
  end
end
